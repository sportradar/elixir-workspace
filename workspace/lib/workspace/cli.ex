defmodule Workspace.Cli do
  @modueldoc false

  @global_cli_opts [
    affected: [
      type: :boolean,
      alias: :a,
      doc: "Run only on affected projects"
    ],
    ignore: [
      type: :string,
      alias: :i,
      keep: true,
      doc: "Ignore the given projects"
    ],
    task: [
      type: :string,
      alias: :t,
      doc: "The task to execute",
      required: true
    ],
    execution_order: [
      type: :string,
      default: "serial",
      doc: "The execution order, one of `serial`, `parallel`, `roots`, `bottom-up`"
    ],
    execution_mode: [
      type: :string,
      default: "process",
      doc: """
      The execution mode. It supports the following values:

        - `process` - every subcommand will be executed as a different process, this
        is the preferred mode for most mix tasks
        - `subtask` - invokes `Mix.Task.run` from the workspace in the given project
      """
    ],
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ],
    workspace_path: [
      type: :string,
      doc: "If set it specifies the root workspace path, defaults to current directory."
    ]
  ]

  def global_opts, do: @global_cli_opts

  def filter_projects(projects, args, argv) do
    ignored = Enum.map(args[:ignore], &String.to_atom/1)

    selected = Enum.map(argv, &String.to_atom/1)

    Enum.map(projects, fn project ->
      Map.put(project, :skip, skippable?(project, selected, ignored))
    end)
  end

  defp skippable?(%{app: app}, [], ignored), do: app in ignored
  defp skippable?(%{app: app}, selected, ignored), do: app not in selected || app in ignored

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
