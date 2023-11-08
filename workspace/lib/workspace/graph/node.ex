defmodule Workspace.Graph.Node do
  @moduledoc """
  A `Workspace.Graph` node.

  A node represents a workspace package. It can also include external packages.
  """

  @typedoc """
  A workspace graph node struct.

  It includes the following fields:

  * `:app` - The package name. This should be unique across the graph
  (including any external package). Required.
  * `:type` - The type of the node. Currently the following types are
  supported but it is open ended for future extensions:
    * `:workspace` - Represents a workspace project.
    * `:external` - Represents an external dependency.
  * `:project` - For packages of type `:workspace` this holds the `Workspace.Project`
  of the current `app`.
  * `:metadata` - Arbitrary keyword list for setting metadata.
  """
  @type t :: %__MODULE__{
          app: atom(),
          type: atom(),
          project: nil | Workspace.Project.t(),
          metadata: keyword()
        }

  @enforce_keys [:app, :type]
  defstruct app: nil, type: nil, project: nil, metadata: []

  @doc """
  Create a new node with the given `app` and `type`.

  ## Options

  * `:project` - The workspace project, required for a node of type `:workspace`, ignored
  otherwise
  * `:metadata` - Arbitrary node metadata.
  """
  @spec new(app :: atom(), type :: atom()) :: t()
  def new(app, type, opts \\ []) when is_atom(app) do
    opts = Keyword.validate!(opts, project: nil, metadata: [])

    new(app, type, opts[:project], opts[:metadata])
  end

  defp new(app, :workspace, project, metadata) do
    validate_project!(app, project)

    %__MODULE__{app: app, type: :workspace, project: project, metadata: metadata}
  end

  defp new(app, :external, _project, metadata) do
    %__MODULE__{app: app, type: :external, metadata: metadata}
  end

  defp validate_project!(app, %Workspace.Project{} = project) do
    if project.app != app do
      raise ArgumentError,
            "invalid :workspace project graph node, expected the " <>
              "project app to be: #{inspect(app)}, got: #{inspect(project.app)}"
    end

    :ok
  end

  defp validate_project!(app, project) do
    raise ArgumentError,
          "invalid project for #{inspect(app)}, a workspace graph node must include " <>
            "a `Workspace.Project`, got: #{inspect(project)}"
  end
end
