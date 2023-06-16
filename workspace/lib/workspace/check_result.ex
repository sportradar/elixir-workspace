defmodule Workspace.CheckResult do
  defstruct checker: nil,
            project: nil,
            status: nil,
            error: nil,
            # should be set by checkers on failure, used for printing errors
            meta: [],
            # TODO: remove instead pass the check to the struct
            index: nil

  def new(checker, project) do
    %__MODULE__{
      checker: checker,
      project: project
    }
  end

  def set_status(result, :ok), do: %__MODULE__{result | status: :ok}

  def set_status(result, {:error, metadata}),
    do: %__MODULE__{result | status: :error, meta: metadata}

  def set_index(result, index), do: %__MODULE__{result | index: index}
end
