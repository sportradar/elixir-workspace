defmodule CliOptions.Docs do
  @moduledoc false

  @doc """
  Pretty prints a cli options parser example.

  The code input is expected to be of the form

  ```
  some code

  >>>

  some more code

  >>>
  ```

  where `>>>` corresponds to placeholders for printing the output up to this
  point.
  """
  @spec cli_fence(code :: String.t(), opts :: keyword()) :: String.t()
  def cli_fence(code, _opts \\ []) do
    code_blocks =
      String.split(code, ">>>") |> Enum.reject(fn block -> String.trim(block) == "" end)

    results =
      code_blocks
      |> Enum.with_index(1)
      |> Enum.map(fn {_code_block, index} ->
        relative_code = Enum.take(code_blocks, index) |> Enum.join("\n")
        {result, _} = Code.eval_string(relative_code, [], __ENV__)
        result
      end)

    output =
      Enum.zip(code_blocks, results)
      |> Enum.flat_map(fn {code_block, result} ->
        [
          code_block_with_iex_prefix(code_block),
          inspect_result(result)
        ]
      end)
      |> Enum.join("\n")

    """
    ```elixir
    #{output}
    ```
    """
  end

  defp code_block_with_iex_prefix(code) do
    code =
      Code.format_string!(code)
      |> IO.iodata_to_binary()
      |> String.replace("\n", "\n...> ")

    "iex> " <> code
  end

  defp inspect_result(result) do
    inspect(result, pretty: true) <> "\n"
  end
end
