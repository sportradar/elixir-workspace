defmodule Workspace.Graph.Node do
  @moduledoc false

  # A node represents a workspace package. It can also include external packages
  # and paths that workspace projects explicitly depend on.

  @typedoc """
  A workspace graph node struct.

  It includes the following fields:

  * `:app` - The package name. This should be unique across the graph
  (including any external package). Required for `:workspace` and `:external`
  nodes, `nil` for `:path` nodes.
  * `:type` - The type of the node. Currently the following types are
  supported but it is open ended for future extensions:
    * `:workspace` - Represents a workspace project.
    * `:external` - Represents an external dependency.
    * `:path` - Represents a path pattern declared in a project's `:affected_by`.
  * `:path` - The expanded path pattern of a `:path` node, `nil` otherwise. This
  is unique across the graph.
  * `:label` - The path pattern of a `:path` node relative to the workspace root,
  used for displaying it. `nil` for other node types.
  * `:metadata` - Arbitrary keyword list for setting metadata.
  """
  @type t :: %__MODULE__{
          app: atom() | nil,
          type: :workspace | :external | :path,
          path: String.t() | nil,
          label: String.t() | nil,
          metadata: keyword()
        }

  @valid_types [:workspace, :external]

  @enforce_keys [:app, :type]
  defstruct app: nil, type: nil, path: nil, label: nil, metadata: []

  @doc """
  Create a new node with the given `app` and `type`.

  ## Options

  * `:project` - The workspace project, required for a node of type `:workspace`, ignored
  otherwise
  * `:metadata` - Arbitrary node metadata.
  """
  @spec new(app :: atom(), type :: atom(), opts :: keyword()) :: t()
  def new(app, type, opts \\ []) when is_atom(app) and type in @valid_types do
    opts = Keyword.validate!(opts, metadata: [])

    %__MODULE__{app: app, type: type, metadata: opts[:metadata]}
  end

  @doc """
  Create a new `:path` node for the given expanded `path` pattern.

  The `workspace_path` is used for generating the node's `:label`.

  ## Options

  * `:metadata` - Arbitrary node metadata.
  """
  @spec path(path :: String.t(), workspace_path :: String.t(), opts :: keyword()) :: t()
  def path(path, workspace_path, opts \\ []) when is_binary(path) do
    opts = Keyword.validate!(opts, metadata: [])

    %__MODULE__{
      app: nil,
      type: :path,
      path: path,
      label: Path.relative_to(path, workspace_path, force: true),
      metadata: opts[:metadata]
    }
  end

  @doc """
  Returns `true` if the node is a `:path` node.
  """
  @spec path?(node :: t()) :: boolean()
  def path?(%__MODULE__{type: type}), do: type == :path
end
