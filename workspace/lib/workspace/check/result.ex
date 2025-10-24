defmodule Workspace.Check.Result do
  @moduledoc """
  A struct holding a check's result.

  Contains info about the checked project if applicable, the check's config
  and the check status and metadata.
  """

  @valid_statuses [:ok, :error, :warn, :skip]

  @typedoc """
  The internal representation of a workspace check result.

  It includes the following fields:

  * `:module` - the underlying check module implementing the `Workspace.Check` behaviour
  * `:check` - the check configuration
  * `:project` - the `Workspace.Project` on which the check was executed
  * `:status` - the status of the check, will be `:ok` in case of success, `:error` in
  case of failure or `:skip` if the check was skipped for the current project.
  * `:meta` - arbitrary check metadata
  """
  @type t :: %__MODULE__{
          module: module(),
          check: keyword(),
          project: Workspace.Project.t(),
          status: nil | :ok | :error | :skip,
          meta: nil | keyword()
        }

  @enforce_keys [:module, :check, :project]
  defstruct module: nil,
            check: nil,
            project: nil,
            status: nil,
            # should be set by checks
            meta: []

  @doc """
  Initializes a check results struct for the given `check` and `project`
  """
  @spec new(check :: keyword(), project :: Workspace.Project.t()) :: t()
  def new(check, project) do
    %__MODULE__{
      module: check[:module],
      check: check,
      project: project
    }
  end

  @doc """
  Sets the result's status.
  """
  @spec set_status(result :: t(), status :: atom()) :: t()
  def set_status(%__MODULE__{} = result, status) when status in @valid_statuses,
    do: %{result | status: status}

  @doc """
  Sets the result's metadata.
  """
  @spec set_metadata(result :: t(), metadata :: keyword()) :: t()
  def set_metadata(%__MODULE__{} = result, metadata), do: %{result | meta: metadata}
end
