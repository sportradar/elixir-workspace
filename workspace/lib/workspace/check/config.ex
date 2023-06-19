defmodule Workspace.Check.Config do
  @moduledoc """
  Configuration for a single check
  """

  # TODO: add typedoc
  @type t :: %__MODULE__{
          module: atom(),
          opts: keyword(),
          description: nil | String.t(),
          index: pos_integer()
        }

  @enforce_keys [:module]
  defstruct module: nil,
            opts: [],
            description: nil,
            index: nil

  @doc """
  Loads a `Config` struct from a keyword list.
  """
  @spec from_list(config :: keyword()) :: {:ok, t()} | {:error, binary()}
  def from_list(config) when is_list(config) do
    case Keyword.validate(config, [:module, :opts, :description, :index]) do
      {:ok, config} ->
        {:ok,
         %__MODULE__{
           module: config[:module],
           opts: Keyword.get(config, :opts, []),
           description: config[:description]
         }}

      {:error, invalid} ->
        {:error, "invalid options given to Check.Config: #{inspect(invalid)}"}
    end
  end

  def set_index(check, index), do: %__MODULE__{check | index: index}
end
