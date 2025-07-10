defmodule Workspace.List.Formatters.Pretty do
  @moduledoc false

  @behaviour Workspace.List.Formatter

  @impl Workspace.List.Formatter

  alias Workspace.Cli
  def render(workspace, opts) do
    projects = Workspace.projects(workspace)

    case Enum.count(projects, &(not &1.skip)) do
      0 ->
        Cli.log([:bright, :yellow, "No matching projects for the given options", :reset])

      valid ->
        Cli.log([
          "Found ",
          :bright,
          :blue,
          "#{valid} workspace projects",
          :reset,
          " matching the given options."
        ])
    end

    max_project_length = max_project_length(projects)

    projects
    |> Enum.sort_by(& &1.app)
    |> Enum.each(&print_project_info(&1, max_project_length, opts[:show_status]))
  end

  defp max_project_length([]), do: 0

  defp max_project_length(projects) do
    projects
    |> Enum.map(fn project -> inspect(project.app) |> String.length() end)
    |> Enum.max()
  end

  defp print_project_info(%Workspace.Project{skip: true}, _length, _show_status), do: :ok

  defp print_project_info(project, max_project_length, show_status) do
    indent_size = max_project_length - String.length(inspect(project.app))
    indent = String.duplicate(" ", indent_size)

    Cli.log([
      "  * ",
      Cli.project_name(project, show_status: show_status, pretty: true),
      indent,
      :light_black,
      " ",
      Path.relative_to(project.mix_path, project.workspace_path),
      :reset,
      description(project.config[:description]),
      tags(project.tags)
    ])
  end

  defp description(nil), do: ""
  defp description(doc) when is_binary(doc), do: [" - ", doc]

  defp tags([]), do: []

  defp tags(tags) do
    tags =
      Enum.map(tags, fn tag -> [:tag, Workspace.Project.format_tag(tag), :reset] end)
      |> Enum.intersperse(", ")

    [" " | tags]
  end
end
