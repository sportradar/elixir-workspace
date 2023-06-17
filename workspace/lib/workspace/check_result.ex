defmodule Workspace.CheckResult do
  @moduledoc """
  A checker's result

  Contains info about the checked project if applicable, the checker config
  and the check status and metadata.
  """

  alias __MODULE__

  @type t :: %CheckResult{
          checker: module(),
          project: atom(),
          status: :ok | :error | :skip,
          meta: keyword(),
          index: pos_integer()
        }

  defstruct checker: nil,
            project: nil,
            status: nil,
            # should be set by checkers
            meta: [],
            # TODO: remove instead pass the check to the struct
            index: nil

  def new(checker, project) do
    %__MODULE__{
      checker: checker,
      project: project
    }
  end

  def set_status(result, status), do: %__MODULE__{result | status: status}

  def set_metadata(result, metadata), do: %__MODULE__{result | meta: metadata}

  def set_index(result, index), do: %__MODULE__{result | index: index}
end
