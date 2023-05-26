defmodule Workspace.Cli do
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
    mode: [
      type: :string,
      default: :serial,
      doc: "The execution mode, one of `serial`, `parallel`, `roots`, `bottom-up`"
    ],
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ]
  ]

  def global_opts, do: @global_cli_opts

  def filter_projects(projects, args, argv) do
    ignored =
      args
      |> Keyword.get_values(:ignore)
      |> Enum.map(&String.to_atom/1)

    selected = Enum.map(argv, &String.to_atom/1)

    Enum.map(projects, fn project ->
      Map.put(project, :skip, skippable?(project, selected, ignored))
    end)
  end

  defp skippable?(%{app: app}, [], ignored), do: app in ignored
  defp skippable?(%{app: app}, selected, ignored), do: app not in selected || app in ignored
end
