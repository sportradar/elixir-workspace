defmodule Workspace.Check.Config do
  @schema [
    module: [
      type: :atom,
      required: true,
      doc: "The `Workspace.Check` module to be used."
    ],
    opts: [
      type: :keyword_list,
      doc: "The check's custom options."
    ],
    description: [
      type: :string,
      doc: "An optional description of the check"
    ]
  ]

  @moduledoc """
  Configuration for a single check

  ## Options

  #{NimbleOptions.docs(@schema)}
  """

  @doc """
  Loads a `Config` struct from a keyword list.
  """
  @spec from_list(config :: keyword()) ::
          {:ok, keyword()} | {:error, NimbleOptions.ValidationError.t()}
  def from_list(config) do
    NimbleOptions.validate(config, @schema)
  end

  def set_index(check, index), do: Keyword.put(check, :index, index)
end
