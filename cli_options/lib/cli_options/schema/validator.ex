defmodule CliOptions.Schema.Validator do
  @moduledoc false

  # A minimal keyword list validator, covering only the needs of `CliOptions`.
  #
  # A validation schema is a keyword list mapping each supported key to its
  # settings. The following settings are supported:
  #
  #   * `:type` - the expected type of the value, see `validate_type/3` for the
  #     supported types.
  #   * `:default` - the value to be used if the key is not present.
  #   * `:required` - if set the key must be present.

  @doc """
  Validates the given `opts` against the given `schema`.

  Returns `{:ok, opts}` with the default values applied, or `{:error, message}`
  with a human readable error message.
  """
  @spec validate(opts :: keyword(), schema :: keyword()) ::
          {:ok, keyword()} | {:error, String.t()}
  def validate(opts, schema) do
    with :ok <- validate_keyword_list(opts),
         :ok <- validate_known_keys(opts, schema),
         :ok <- validate_required_keys(opts, schema),
         :ok <- validate_values(opts, schema) do
      {:ok, apply_defaults(opts, schema)}
    end
  end

  defp validate_keyword_list(opts) do
    case Keyword.keyword?(opts) do
      true -> :ok
      false -> {:error, "expected a keyword list, got: #{inspect(opts)}"}
    end
  end

  defp validate_known_keys(opts, schema) do
    case Keyword.keys(opts) -- Keyword.keys(schema) do
      [] ->
        :ok

      unknown ->
        {:error,
         "unknown options #{inspect(unknown)}, valid options are: #{inspect(Keyword.keys(schema))}"}
    end
  end

  defp validate_required_keys(opts, schema) do
    missing =
      for {key, settings} <- schema,
          settings[:required],
          not Keyword.has_key?(opts, key),
          do: key

    case missing do
      [] -> :ok
      [key | _rest] -> {:error, "required #{inspect(key)} option not found"}
    end
  end

  defp validate_values(opts, schema) do
    Enum.reduce_while(opts, :ok, fn {key, value}, :ok ->
      case validate_type(schema[key][:type], key, value) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  # an option without a type accepts any value
  defp validate_type(nil, _key, _value), do: :ok
  defp validate_type(:any, _key, _value), do: :ok

  defp validate_type(:string, _key, value) when is_binary(value), do: :ok
  defp validate_type(:string, key, value), do: type_error(key, "string", value)

  defp validate_type(:boolean, _key, value) when is_boolean(value), do: :ok
  defp validate_type(:boolean, key, value), do: type_error(key, "boolean", value)

  defp validate_type(:atom, _key, value) when is_atom(value), do: :ok
  defp validate_type(:atom, key, value), do: type_error(key, "atom", value)

  defp validate_type({:in, values}, key, value) do
    case value in values do
      true -> :ok
      false -> type_error(key, "one of #{inspect(values)}", value)
    end
  end

  defp validate_type({:list, subtype}, key, value) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {element, index}, :ok ->
      case validate_type(subtype, {:list_element, index}, element) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "invalid list in #{inspect(key)} option: #{reason}"}}
      end
    end)
  end

  defp validate_type({:list, _subtype}, key, value), do: type_error(key, "list", value)

  defp validate_type({:or, subtypes}, key, value) do
    case Enum.any?(subtypes, fn subtype -> validate_type(subtype, key, value) == :ok end) do
      true ->
        :ok

      false ->
        expected = Enum.map_join(subtypes, " or ", &type_name/1)

        {:error, "expected #{inspect(key)} option to be #{expected}, got: #{inspect(value)}"}
    end
  end

  defp type_name({:in, values}), do: "one of #{inspect(values)}"
  defp type_name(type), do: Atom.to_string(type)

  defp type_error(key, expected, value),
    do:
      {:error,
       "invalid value for #{describe_key(key)}: expected #{expected}, got: #{inspect(value)}"}

  defp describe_key({:list_element, index}), do: "list element at position #{index}"
  defp describe_key(key), do: "#{inspect(key)} option"

  # notice that the defaults are prepended in the schema's declaration order
  defp apply_defaults(opts, schema) do
    Enum.reduce(schema, opts, fn {key, settings}, acc ->
      case Keyword.has_key?(settings, :default) and not Keyword.has_key?(acc, key) do
        true -> [{key, settings[:default]} | acc]
        false -> acc
      end
    end)
  end
end
