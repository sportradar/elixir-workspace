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

  def newline, do: Mix.shell().info("")

  @doc """
  Helper function for console log messages

  ## Options

  - `:prefix` the prefix to be used, defaults to "==> ". If set to `false`
  no prefix is applied.
  """
  @spec log(
          message :: IO.ANSI.ansidata(),
          opts :: Keyword.t()
        ) ::
          :ok
  def log(message, opts \\ []) do
    prefix =
      case opts[:prefix] do
        nil -> "==> "
        false -> ""
        other when is_binary(other) -> other
      end

    Mix.shell().info([prefix, message])
  end

  @doc """
  Helper function for logging a message with a title

  Each log message conists of the following sections:

  - `prefix` a prefix for each log message, defaults to "==> ". Can be
  configured through the `prefix` option. If set to `false` no prefix
  is applied.
  - `title` a string representing the title of the log message, e.g.
  an application name, a command or a log level. 
  - `separator` separator between the title and the main message, defaults
  to a space.
  - `message` the message to be printed, can be any text

  ## Options

  - `:prefix` - the prefix to be used, defaults to `==> `
  - `:separator` - the separator to be used between title and message, defaults
  to ` - `

  ## Examples

  You can combine it with other helper CLI functions like `highlight` for
  rich text log messages.

  ```elixir
  # Default invocation
  Cli.log(":foo", "a message") ##> ==> :foo - a message

  # with a different prefix
  Cli.log(":foo", "a message", prefix: "> ") ##> > :foo - a message

  # with highlighted sections
  Cli.log(project_name(project, show_status: true), highlight(message, [:bright, :red]))
  ```
  """
  @spec log_with_title(
          section :: IO.ANSI.ansidata(),
          message :: IO.ANSI.ansidata(),
          opts :: Keyword.t()
        ) ::
          :ok
  def log_with_title(title, message, opts \\ []) do
    separator = opts[:separator] || " - "

    log([title, separator, message], opts)
  end

  def status_color(:error), do: :red
  def status_color(:error_ignore), do: :magenta
  def status_color(:ok), do: :green
  def status_color(:skip), do: :white
  def status_color(:warn), do: :yellow

  def hl(text, :code), do: highlight(text, :light_cyan)

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
          text :: IO.ANSI.ansidata(),
          ansi_codes :: IO.ANSI.ansicode() | [IO.ANSI.ansicode()]
        ) ::
          IO.ANSI.ansidata()
  def highlight(text, ansi_code) when is_atom(ansi_code), do: highlight(text, [ansi_code])
  def highlight(text, ansi_code) when is_binary(text), do: highlight([text], ansi_code)

  def highlight(text, ansi_codes) when is_list(text) and is_list(ansi_codes) do
    ansi_codes ++ [text, :reset]
  end

  @doc """
  Format the project name with the default styling and status info if needed.

  ## Options

  * `:show_status` - if set to `true` it color codes the name based on the status
  of the project and appends status icons as following:
    * `:modified` - `✚` (bright red)
    * `:affected` - `●` (bright yellow)
    * `:unaffected` - `✔` (:bright green)
  * `:defaule_style` - can be used to change the default style (`:light_cyan`)
  """
  @spec project_name(project :: Workspace.Project.t(), opts :: keyword()) :: IO.ANSI.ansidata()
  def project_name(project, opts \\ []) do
    show_status = opts[:show_status] || false
    default_style = opts[:default_style] || [:light_cyan]

    cond do
      show_status ->
        [
          highlight(inspect(project.app), project_status_style(project.status, default_style)),
          project_status_suffix(project.status)
        ]

      true ->
        highlight(inspect(project.app), default_style)
    end
  end

  defp project_status_style(:affected, _default_style), do: [:yellow]
  defp project_status_style(:modified, _default_style), do: [:bright, :red]
  defp project_status_style(_other, default_style), do: default_style

  defp project_status_suffix(:modified), do: [:bright, :red, " ✚", :reset]
  defp project_status_suffix(:affected), do: [:bright, :yellow, " ●", :reset]
  defp project_status_suffix(_other), do: [:bright, :green, " ✔", :reset]
end
