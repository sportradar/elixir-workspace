defmodule Workspace.Utils.Path do
  @moduledoc false

  @doc """
  Checks if `base` is a parent directory of `path`

  Both paths are expanded before returning the relative path.

  ## Examples

      iex> Workspace.Utils.Path.parent_dir?("/usr/local", "/usr/local/foo/tmp")
      true

      iex> Workspace.Utils.Path.parent_dir?("/usr/local_foo", "/usr/local/foo/tmp")
      false
  """
  @spec parent_dir?(base :: Path.t(), path :: Path.t()) :: boolean()
  def parent_dir?(base, path) do
    base =
      base
      |> Path.expand()
      |> Path.split()

    path =
      path
      |> Path.expand()
      |> Path.split()

    starts_with?(path, base)
  end

  defp starts_with?(_path, []), do: true

  defp starts_with?([head | path_tail], [head | base_tail]),
    do: starts_with?(path_tail, base_tail)

  defp starts_with?(_path, _tail), do: false

  @doc """
  Checks if `path` matches the given glob `pattern`

  Matching is purely string based, the filesystem is never accessed, so it
  works for deleted files as well. A path matches if either the path itself
  or any of its parent directories matches the pattern, e.g. a directory
  pattern matches all files under it.

  Both the pattern and the path are expanded before matching. The following
  wildcards are supported:

    * `*` - matches any characters except path separators
    * `**` - matches any characters including path separators
    * `?` - matches a single character except path separators
    * `{a,b}` - matches any of the comma separated alternatives
    * `[abc]` - matches any of the enclosed characters

  ## Examples

      iex> Workspace.Utils.Path.glob_match?("/shared/*.ex", "/shared/config.ex")
      true

      iex> Workspace.Utils.Path.glob_match?("/shared/*.ex", "/shared/nested/config.ex")
      false

      iex> Workspace.Utils.Path.glob_match?("/shared/**/*.ex", "/shared/nested/config.ex")
      true

      iex> Workspace.Utils.Path.glob_match?("/shared", "/shared/nested/config.ex")
      true

      iex> Workspace.Utils.Path.glob_match?("/shared", "/shared_foo/config.ex")
      false
  """
  @spec glob_match?(pattern :: Path.t(), path :: Path.t()) :: boolean()
  def glob_match?(pattern, path) do
    pattern
    |> glob_to_regex()
    |> Regex.match?(Path.expand(path))
  end

  @doc """
  Compiles the given glob `pattern` into a regular expression.

  The pattern is expanded before compilation. The returned regex matches
  a path if the path or any of its parent directories matches the pattern.
  Check `glob_match?/2` for the supported wildcards.

  If a `literal_base` is given, the leading path segments shared by the expanded
  pattern and the base are matched literally. This is useful for patterns
  expanded relative to a base directory, e.g. a project's path, since any
  wildcard characters in the base directory name are not part of the glob.
  """
  @spec glob_to_regex(pattern :: Path.t(), literal_base :: Path.t() | nil) :: Regex.t()
  def glob_to_regex(pattern, literal_base \\ nil) do
    segments = pattern |> Path.expand() |> Path.split()
    base_segments = if literal_base, do: literal_base |> Path.expand() |> Path.split(), else: []

    {literal, glob} = Enum.split(segments, common_prefix_length(segments, base_segments, 0))

    source =
      case {literal, glob} do
        {[], glob} -> glob |> Path.join() |> translate()
        {literal, []} -> literal |> Path.join() |> Regex.escape()
        {literal, glob} -> Regex.escape(dir_prefix(literal)) <> translate(Path.join(glob))
      end

    Regex.compile!("^" <> source <> "(?:/.*)?$")
  end

  # joins the segments with a trailing separator, e.g. ["/"] is already "/"
  defp dir_prefix(segments) do
    path = Path.join(segments)
    if String.ends_with?(path, "/"), do: path, else: path <> "/"
  end

  defp common_prefix_length([head | rest], [head | base_rest], count),
    do: common_prefix_length(rest, base_rest, count + 1)

  defp common_prefix_length(_segments, _base_segments, count), do: count

  defp translate(glob), do: glob |> String.graphemes() |> translate_glob(0, [])

  # depth tracks the nesting level of `{}` alternatives, commas are
  # treated as separators only within braces
  defp translate_glob([], _depth, acc), do: acc |> Enum.reverse() |> Enum.join()

  defp translate_glob(["*", "*", "/" | rest], depth, acc),
    do: translate_glob(rest, depth, ["(?:.*/)?" | acc])

  defp translate_glob(["*", "*" | rest], depth, acc),
    do: translate_glob(rest, depth, [".*" | acc])

  defp translate_glob(["*" | rest], depth, acc), do: translate_glob(rest, depth, ["[^/]*" | acc])
  defp translate_glob(["?" | rest], depth, acc), do: translate_glob(rest, depth, ["[^/]" | acc])

  # a brace without a closing one is matched literally
  defp translate_glob(["{" | rest], depth, acc) do
    if "}" in rest,
      do: translate_glob(rest, depth + 1, ["(?:" | acc]),
      else: translate_glob(rest, depth, ["\\{" | acc])
  end

  defp translate_glob(["}" | rest], depth, acc) when depth > 0,
    do: translate_glob(rest, depth - 1, [")" | acc])

  defp translate_glob(["," | rest], depth, acc) when depth > 0,
    do: translate_glob(rest, depth, ["|" | acc])

  defp translate_glob(["[" | rest], depth, acc) do
    case Enum.split_while(rest, &(&1 != "]")) do
      {chars, ["]" | rest]} ->
        class = chars |> Enum.join() |> String.replace("\\", "\\\\")
        translate_glob(rest, depth, ["[" <> class <> "]" | acc])

      _no_closing_bracket ->
        translate_glob(rest, depth, ["\\[" | acc])
    end
  end

  defp translate_glob([char | rest], depth, acc),
    do: translate_glob(rest, depth, [Regex.escape(char) | acc])
end
