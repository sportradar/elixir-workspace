defmodule Workspace.CheckResult do
  @moduledoc """
  A checker's result

  Contains info about the checked project if applicable, the checker config
  and the check status and metadata.
  """

  alias __MODULE__

  @type t :: %CheckResult{
          checker: module(),
          check: keyword(),
          project: Workspace.Project.t(),
          status: :ok | :error | :skip,
          meta: keyword(),
          index: pos_integer()
        }

  # TODO: add enforce keys
  defstruct checker: nil,
            check: nil,
            project: nil,
            status: nil,
            # should be set by checkers
            meta: [],
            # TODO: remove instead pass the check to the struct
            index: nil

  def new(check, project) do
    %__MODULE__{
      checker: check[:check],
      check: check,
      project: project
    }
  end

  def set_status(result, status), do: %__MODULE__{result | status: status}

  def set_metadata(result, metadata), do: %__MODULE__{result | meta: metadata}

  def set_index(result, index), do: %__MODULE__{result | index: index}
end
