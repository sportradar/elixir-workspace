defmodule Workspace.Graph.Node do
  @moduledoc false

  # A node represents a workspace package. It can also include external packages.

  @typedoc """
  A workspace graph node struct.

  It includes the following fields:

  * `:app` - The package name. This should be unique across the graph
  (including any external package). Required.
  * `:type` - The type of the node. Currently the following types are
  supported but it is open ended for future extensions:
    * `:workspace` - Represents a workspace project.
    * `:external` - Represents an external dependency.
  * `:metadata` - Arbitrary keyword list for setting metadata.
  """
  @type t :: %__MODULE__{
          app: atom(),
          type: :workspace | :external,
          metadata: keyword()
        }

  @valid_types [:workspace, :external]

  @enforce_keys [:app, :type]
  defstruct app: nil, type: nil, metadata: []

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
end
