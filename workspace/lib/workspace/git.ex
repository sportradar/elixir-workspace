defmodule Workspace.Git do
  @moduledoc """
  Helper git related functions
  """

  @type change_type :: :uncommitted | :untracked | :modified

  @doc """
  Get the git repo root of the given path

  Returns `{:ok, path}` in case of success or `{:error, reason}` in
  case of failure.

  If the given path is under a symlinked directory, the symlinked form of the
  root is returned, so that it can be safely compared with paths derived from
  the given path. If the path is itself a symlink pointing inside a repository
  there is no symlinked form of the root and the resolved root is returned.

  ## Options

  * `:cd` - the path to use for getting the git root, if not
  set defaults to the current working directory.
  """
  @spec root(opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def root(opts \\ []) do
    cd = Path.expand(opts[:cd] || File.cwd!())

    # --show-toplevel returns the resolved path, we strip the relative path of
    # cd in the repo (--show-prefix) from cd in order to keep its symlinked form
    with {:ok, output} <- git_in_path(cd, ~w[rev-parse --show-toplevel --show-prefix]) do
      {toplevel, prefix} =
        case String.split(output, "\n") do
          [toplevel] -> {toplevel, ""}
          [toplevel, prefix] -> {toplevel, prefix}
        end

      {:ok, strip_suffix(cd, prefix) || toplevel}
    end
  end

  defp strip_suffix(path, suffix) do
    path = Path.split(path)
    suffix = Path.split(suffix)
    {base, tail} = Enum.split(path, length(path) - length(suffix))

    if tail == suffix, do: Path.join(base), else: nil
  end

  @doc """
  Detects the changed files in the given directory.

  By default the following files are included:

    - Uncommitted files in the working directory
    - Untracked files in the working directory
    - If `:base` is provided it also includes the files changed on `:head` since
    it diverged from `:base`, e.g. `git diff base...head`. `:head` defaults to
    `HEAD` if not set.

  A list of tuples of the form `{"path/to/changed/file", change_type}` is
  returned, where `change_type` can be one of the following:

  * `:uncommitted` - for changed files under version control that are not committed
  * `:untracked` - for new files that are not under version control
  * `:modified` - for changed committed files on `:head` since it diverged from `:base`

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
    * `:base` (`t:binary/0`) - The base reference to use for comparing to the `HEAD`,
    can be a branch, a commit or any other `git` reference.
    * `:head` (`t:binary/0`) - The `head` to use for comparing to `:base`, if not set
    defaults to `HEAD`. Can be any git reference
  """
  @spec changed(opts :: keyword()) ::
          {:ok, [{binary(), change_type()}]} | {:error, binary()}
  def changed(opts \\ []) do
    with {:ok, uncommitted} <- uncommitted_files(cd: opts[:cd]),
         {:ok, untracked} <- untracked_files(cd: opts[:cd]),
         {:ok, changed} <- maybe_changed_files(opts[:base], opts[:head] || "HEAD", cd: opts[:cd]) do
      changed =
        [
          annotate_change(uncommitted, :uncommitted),
          annotate_change(untracked, :untracked),
          annotate_change(changed, :modified)
        ]
        |> Enum.concat()
        |> Enum.sort_by(fn {file, _change} -> file end)

      {:ok, changed}
    end
  end

  defp annotate_change(files, change), do: Enum.map(files, fn file -> {file, change} end)

  defp maybe_changed_files(nil, _head, _opts), do: {:ok, []}
  defp maybe_changed_files(base, head, opts), do: changed_files(base, head, opts)

  @doc """
  Returns a list of uncommitted files

  Uncommitted are considered the files that are staged but not committed yet.

  If the repository has no commits yet, all staged files are considered
  uncommitted.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec uncommitted_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def uncommitted_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    # without any commit HEAD cannot be resolved, so we diff the index instead
    diff_against =
      case git_in_path(cd, ~w[rev-parse --verify --quiet HEAD]) do
        {:ok, _commit} -> "HEAD"
        {:error, _reason} -> "--cached"
      end

    git_files(cd, ~w[diff --name-only --no-renames] ++ [diff_against])
  end

  @doc """
  Returns the files of the repository

  Both tracked files and untracked files which are not ignored are
  included. The paths are relative to the `:cd` path.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_files(cd, ~w[ls-files --cached --others --exclude-standard])
  end

  @doc """
  Get list of untracked files

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec untracked_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def untracked_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_files(cd, ~w[ls-files --others --exclude-standard])
  end

  @doc """
  Get the changed files of the `head` git reference since it diverged from `base`.

  The `head` is compared against the merge base of `base` and `head`, e.g.
  changes of `base` after `head` diverged from it are not included. This is
  equivalent to `git diff base...head`.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec changed_files(base :: binary(), head :: binary(), opts :: keyword()) ::
          {:ok, [binary()]} | {:error, binary()}
  def changed_files(base, head, opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_files(cd, ["diff", "--name-only", "--no-renames", "--relative", "#{base}...#{head}"])
  end

  defp git_in_path(path, git_command, opts \\ []) do
    {output, status} =
      File.cd!(path, fn ->
        System.cmd("git", git_command, stderr_to_stdout: true)
      end)

    case status do
      0 ->
        {:ok, if(Keyword.get(opts, :trim, true), do: String.trim(output), else: output)}

      status ->
        {:error,
         "git #{Enum.join(git_command, " ")} failed with #{status}: #{String.trim(output)}"}
    end
  end

  # Runs a git command listing files. With -z paths are NUL separated and never
  # quoted, e.g. for non ASCII characters, so they are returned verbatim.
  defp git_files(path, [subcommand | args]) do
    with {:ok, output} <- git_in_path(path, [subcommand, "-z" | args], trim: false) do
      {:ok, output |> String.split(<<0>>) |> Enum.reject(&(&1 == ""))}
    end
  end
end
