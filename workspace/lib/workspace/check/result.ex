defmodule Workspace.Check.Result do
  @moduledoc """
  A checker's result

  Contains info about the checked project if applicable, the checker config
  and the check status and metadata.
  """

  @valid_statuses [:ok, :error, :warn, :skip]

  # TODO: add typedoc
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
            # should be set by checkers
            meta: []

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
  def set_status(result, status) when status in @valid_statuses,
    do: %__MODULE__{result | status: status}

  @doc """
  Sets the result's metadata.
  """
  @spec set_metadata(result :: t(), metadata :: keyword()) :: t()
  def set_metadata(result, metadata), do: %__MODULE__{result | meta: metadata}
end
