defmodule Workspace.Cli do
  @moduledoc """
  Helper functions for the mix tasks
  """

  @doc """
  Merges the common options with the extra
  """
  @spec options(common :: [atom()], extra :: keyword()) :: keyword()
  def options(common, extra \\ []) do
    common
    |> Enum.map(fn option -> {option, Workspace.Cli.Options.option(option)} end)
    |> Keyword.new()
    |> Keyword.merge(extra)
  end

  def filter_projects(projects, opts) do
    ignored = Enum.map(opts[:ignore], &String.to_atom/1)
    selected = Enum.map(opts[:project], &String.to_atom/1)

    Enum.map(projects, fn project ->
      Map.put(project, :skip, skippable?(project, selected, ignored))
    end)
  end

  defp skippable?(%{app: app}, [], ignored), do: app in ignored
  defp skippable?(%{app: app}, selected, ignored), do: app not in selected || app in ignored

  @doc """
  Highlights the given `text` with the given ansi codes

  ## Examples

      iex> Workspace.Cli.highlight("a blue text", :blue)
      [:blue, ["a blue text"], :reset]

      iex> Workspace.Cli.highlight(["some ", "text"], :blue)
      [:blue, ["some ", "text"], :reset]

      iex> Workspace.Cli.highlight("some text", [:bright, :green])
      [:bright, :green, ["some text"], :reset]
  """
  @spec highlight(text :: binary() | [binary()], ansi_codes :: IO.ANSI.ansicode() | [IO.ANSI.ansicode()]) ::
          IO.ANSI.ansidata()
  def highlight(text, ansi_code) when is_atom(ansi_code), do: highlight(text, [ansi_code])
  def highlight(text, ansi_code) when is_binary(text), do: highlight([text], ansi_code)

  def highlight(text, ansi_codes) when is_list(text) and is_list(ansi_codes) do
    ansi_codes ++ [text, :reset]
  end

  @doc """
  Prints an info (blue) message

  See also `log/4`
  """
  @spec info(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def info(command, message, opts \\ []), do: log(:blue, command, message, opts)

  @doc """
  Prints a success (green) message

  See also `log/4`
  """
  @spec success(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def success(command, message, opts \\ []), do: log(:green, command, message, opts)

  @doc """
  Prints an error (red) message

  See also `log/4`
  """
  @spec error(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def error(command, message, opts \\ []), do: log(:red, command, message, opts)

  @doc """
  Prints a warning (yellow) message

  See also `log/4`
  """
  @spec warning(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def warning(command, message, opts \\ []), do: log(:yellow, command, message, opts)

  @doc """
  Generic log message with a colored part

  The command part is colored with the given `color`. You can specify in the
  `opts` list the `prefix` which defaults to (`* `) and `suffix` (which
  defaults to ` `) in order to modify the default message appearance.

  Optionally you can pass an `ansilist` similarly to `c:Mix.Shell.info/1` for
  custom formatting of the `message`.
  """
  @spec log(
          color :: atom(),
          command :: String.t(),
          message :: IO.ANSI.ansidata(),
          opts :: Keyword.t()
        ) ::
          :ok
  def log(color, command, message, opts) when is_binary(message) do
    log(color, command, [message], opts)
  end

  def log(color, command, message, opts) when is_list(message) do
    prefix = Keyword.get(opts, :prefix, "* ")
    suffix = Keyword.get(opts, :suffix, " ")
    Mix.shell().info([color, "#{prefix}#{command}#{suffix}", :reset | message])
  end
end
