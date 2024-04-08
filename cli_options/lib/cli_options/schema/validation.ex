defmodule CliOptions.Schema.Validation do
  @moduledoc false
  # Schema validation

  # we are manually validating the schema for now, could be delegated to NimbleOptions
  # but we want to avoid external dependencies. If it goes out of hand we may consider
  # refactoring it accordingly
  @spec validate!(schema :: keyword()) :: keyword()
  def validate!(schema) do
    for {option, opts} <- schema do
      validate_option!(option, opts)
    end
  end

  defp validate_option!(option, opts) do
    with :ok <- validate_keys(Keyword.keys(opts)),
         {:ok, opts} <- validate_type(opts),
         {:ok, opts} <- validate_names(option, opts),
         :ok <- ensure_boolean_or_nil(opts[:required], :required),
         :ok <- ensure_boolean_or_nil(opts[:multiple], :multiple),
         :ok <- ensure_binary_or_nil(opts[:doc], :doc),
         :ok <- ensure_binary_list_or_nil(opts[:allowed], :allowed),
         {:ok, opts} <- validate_default_value(opts) do
      {option, opts}
    else
      {:error, reason} -> raise ArgumentError, "invalid schema for :#{option}, #{reason}"
    end
  end

  @valid_option_keys [
    :type,
    :long,
    :short,
    :doc,
    :default,
    :required,
    :multiple,
    :aliases,
    :short_aliases,
    :allowed
  ]
  defp validate_keys(keys) do
    invalid_keys = keys -- @valid_option_keys

    case invalid_keys do
      [] -> :ok
      invalid -> {:error, "the following schema keys are not supported: #{inspect(invalid)}"}
    end
  end

  @valid_types [:string, :boolean, :integer, :float, :counter, :atom]

  defp validate_type(opts) do
    opts = Keyword.put_new(opts, :type, :string)
    type = Keyword.fetch!(opts, :type)

    case type in @valid_types do
      true -> {:ok, opts}
      false -> {:error, "invalid type #{inspect(type)}"}
    end
  end

  defp validate_names(option, opts) do
    opts =
      opts
      |> Keyword.put_new(:long, default_long_name(option))
      |> Keyword.put_new(:aliases, [])
      |> Keyword.put_new(:short_aliases, [])

    with :ok <- ensure_binary(opts[:long], :long),
         :ok <- ensure_binary_or_nil(opts[:short], :short),
         :ok <- ensure_binary_list(opts[:aliases], :aliases),
         :ok <- ensure_binary_list(opts[:short_aliases], :short_aliases) do
      {:ok, opts}
    end
  end

  defp default_long_name(option), do: Atom.to_string(option) |> String.replace("_", "-")

  defp ensure_binary_or_nil(nil, _name), do: :ok
  defp ensure_binary_or_nil(value, name), do: ensure_binary(value, name)

  defp ensure_binary(value, _name) when is_binary(value), do: :ok

  defp ensure_binary(value, name),
    do: {:error, "#{inspect(name)} should be a string, got: #{inspect(value)}"}

  defp ensure_binary_list_or_nil(nil, _name), do: :ok
  defp ensure_binary_list_or_nil(values, name), do: ensure_binary_list(values, name)

  defp ensure_binary_list([], _name), do: :ok

  defp ensure_binary_list([head | rest], name) do
    case ensure_binary(head, name) do
      :ok ->
        ensure_binary_list(rest, name)

      _error ->
        {:error,
         "#{inspect(name)} expected a list of strings, got a non string item: #{inspect(head)}"}
    end
  end

  defp ensure_binary_list(value, name),
    do: {:error, "#{inspect(name)} expected a list of strings, got: #{inspect(value)}"}

  defp ensure_boolean_or_nil(nil, _name), do: :ok
  defp ensure_boolean_or_nil(value, _name) when is_boolean(value), do: :ok

  defp ensure_boolean_or_nil(value, name),
    do: {:error, "#{inspect(name)} should be boolean, got: #{inspect(value)}"}

  defp validate_default_value(opts) do
    opts = maybe_add_default_value(opts, opts[:type])

    case validate_type_match(opts[:type], opts[:default]) do
      true ->
        {:ok, opts}

      false ->
        {:error,
         ":default should be of type #{inspect(opts[:type])}, got: #{inspect(opts[:default])}"}
    end
  end

  defp maybe_add_default_value(opts, :boolean), do: Keyword.put_new(opts, :default, false)
  defp maybe_add_default_value(opts, :counter), do: Keyword.put_new(opts, :default, 0)
  defp maybe_add_default_value(opts, _other), do: opts

  defp validate_type_match(_type, nil), do: true

  defp validate_type_match(:integer, value), do: is_integer(value)
  defp validate_type_match(:counter, value), do: is_integer(value)
  defp validate_type_match(:string, value), do: is_binary(value)
  defp validate_type_match(:float, value), do: is_float(value)
  defp validate_type_match(:atom, value), do: is_atom(value)
  defp validate_type_match(:boolean, value), do: is_boolean(value)
end
