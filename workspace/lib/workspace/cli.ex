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

  def newline, do: Mix.shell().info("")
  def log(message), do: log("", message, prefix: "==>", separator: " ")

  @doc """
  Helper function for fancy generic log messages

  Each log message conists of the following sections:

  - `prefix` a prefix for each log message, defaults to "==> ". Can be
  configured through the `prefix` option.
  - `section` a string representing the section of the log message, e.g.
  an application name, a command or a log level. 
  - `separator` separator between the section and the main message, defaults
  to a space.
  - `message` the message to be printed, can be any text

  The following options are supported:

  - `prefix` - the prefix to be used, defaults to `==> `
  - `separator` - the separator to be used, defaults to ` - `
  - `section_style` - the style to be applied for highlighting the section,
  no styling is applied if not set
  - `style` - a highlight style to be applied to the complete message.
  """
  @spec log(
          section :: IO.ANSI.ansidata(),
          message :: IO.ANSI.ansidata(),
          opts :: Keyword.t()
        ) ::
          :ok
  def log(section, message, opts \\ []) do
    prefix = opts[:prefix] || "==> "
    separator = opts[:separator] || " - "
    section_style = opts[:section_style] || []
    style = opts[:style] || []

    Mix.shell().info([
      prefix,
      highlight(section, section_style),
      separator,
      highlight(message, style)
    ])
  end

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
  @spec highlight(
          text :: binary() | [binary()],
          ansi_codes :: IO.ANSI.ansicode() | [IO.ANSI.ansicode()]
        ) ::
          IO.ANSI.ansidata()
  def highlight(text, ansi_code) when is_atom(ansi_code), do: highlight(text, [ansi_code])
  def highlight(text, ansi_code) when is_binary(text), do: highlight([text], ansi_code)

  def highlight(text, ansi_codes) when is_list(text) and is_list(ansi_codes) do
    ansi_codes ++ [text, :reset]
  end
end
