defmodule Mix.Tasks.Workspace.Run do
  @options_schema Workspace.Cli.global_opts()

  @shortdoc "Run a mix command to all projects"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  alias Workspace.Cli

  def run(argv) do
    %{parsed: parsed, args: args, extra: extra} = CliOpts.parse!(argv, @options_schema)

    Workspace.projects()
    |> Workspace.Cli.filter_projects(parsed, args)
    |> Enum.each(fn project -> run_in_project(project, parsed, extra) end)
  end

  defp run_in_project(%{skip: true, app: app}, args, _argv) do
    if args[:verbose] do
      WorkspaceColors.warning("#{args[:task]}", "skipping #{app}")
    end
  end

  defp run_in_project(project, options, argv) do
    task = options[:task]

    project_relative_path = Workspace.relative_path(Path.dirname(project[:path]))
    task_args = [task | argv]

    Cli.info(project_relative_path, "- mix #{Enum.join(task_args, " ")}", prefix: "==> ")

    case options[:execution_mode] do
      "process" ->
        cmd(task, argv, Path.dirname(project[:path]))

      "subtask" ->
        Mix.Project.in_project(project[:app], Path.dirname(project[:path]), fn _mixfile ->
          Mix.Task.run(task, argv)
        end)

      other ->
        Mix.raise("invalid execution mode #{other}, only `process` and `subtask` are supported")
    end
  end

  defp cmd(task, argv, path) do
    mix = System.find_executable("mix")
    args = [task | argv]

    port =
      Port.open({:spawn_executable, mix}, [
        :stream,
        :hide,
        :use_stdio,
        :stderr_to_stdout,
        :binary,
        :exit_status,
        args: args,
        cd: path
      ])

    stream_output([args: args, path: path], port)
  end

  defp stream_output(meta, port) do
    receive do
      {^port, {:data, data}} ->
        IO.write(data)
        stream_output(meta, port)

      {^port, {:exit_status, 0}} ->
        0

      {^port, {:exit_status, status}} ->
        args = Keyword.get(meta, :args)
        path = Keyword.get(meta, :path)
        IO.puts("(under #{path}) `mix #{Enum.join(args, " ")}` failed with status #{status}")
    end
  end
end
