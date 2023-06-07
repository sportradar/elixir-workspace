defmodule Workspace.CheckResult do
  defstruct checker: nil,
            project: nil,
            status: nil,
            error: nil

  def new(checker, project) do
    %__MODULE__{
      checker: checker,
      project: project
    }
  end

  def set_status(result, :ok), do: %__MODULE__{result | status: :ok}

  def set_status(result, {:error, reason}),
    do: %__MODULE__{result | status: :error, error: reason}
end
