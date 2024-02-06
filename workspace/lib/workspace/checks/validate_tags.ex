defmodule Workspace.Checks.ValidateTags do
  @schema NimbleOptions.new!(
            allowed: [
              type: {:list, {:or, [:atom, {:tuple, [:atom, :atom]}]}},
              required: true,
              doc: """
              A list of allowed tags. A tag can either be a single `atom` or a
              scoped tag of the form `{atom, atom}`.
              """
            ]
          )

  @moduledoc """
  Checks that the project's tags are valid.

  This check can be used in order to limit the possible tags assigned to each project
  to a well defined set of allowed values.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  In order to configure this check add the following, under `checks`, in your workspace
  config:

  ```elixir
  [
    module: Workspace.Checks.ValidateTags,
    description: "all projects must adhere to our tags policy",
    opts: [
      allowed: [
        :shared,
        :app,
        :ui,
        {:importance, :critical},
        {:importance, :low}  
      ]
    ]
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    allowed = Keyword.fetch!(check[:opts], :allowed)

    Workspace.Check.check_projects(workspace, check, fn project ->
      validate_tags(project, allowed)
    end)
  end

  defp validate_tags(project, allowed) do
    invalid_tags =
      Enum.reduce(project.tags, [], fn tag, invalid ->
        if tag in allowed do
          invalid
        else
          [tag | invalid]
        end
      end)
      |> Enum.reverse()

    case invalid_tags do
      [] -> {:ok, check_metadata()}
      invalid_tags -> {:error, check_metadata(invalid_tags)}
    end
  end

  defp check_metadata(invalid_tags \\ []) do
    [invalid_tags: invalid_tags]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    [
      "the following tags are not allowed: ",
      :light_red,
      inspect(meta[:invalid_tags]),
      :reset
    ]
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["all tags are valid"]
  end
end
