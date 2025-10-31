defmodule CliOptions.Parser do
  @moduledoc false

  @type parsed_options :: {keyword(), [String.t()], [String.t()]}

  @doc false
  @spec parse(argv :: [String.t()], schema :: CliOptions.Schema.t()) ::
          {:ok, parsed_options()} | {:error, String.t()}
  def parse(argv, %CliOptions.Schema{} = schema) do
    # we split the extra args first (anything after the first --) and then
    # parse the remaining
    {remaining_argv, extra} = split_extra(argv)

    with {:ok, opts, args} <- parse(remaining_argv, schema, [], []),
         {:ok, opts} <- maybe_append_env_values(opts, schema),
         {:ok, opts} <- CliOptions.Schema.validate(opts, schema) do
      {:ok, {opts, args, extra}}
    end
  end

  defp split_extra(argv), do: split_extra(argv, [])

  defp split_extra([], argv), do: {Enum.reverse(argv), []}
  defp split_extra(["--" | rest], argv), do: {Enum.reverse(argv), rest}
  defp split_extra([arg | rest], argv), do: split_extra(rest, [arg | argv])

  defp parse(argv, schema, opts, args) do
    case next(argv, schema) do
      nil ->
        {:ok, Enum.reverse(opts), Enum.reverse(args)}

      {:option, option, value, rest} ->
        case put_option(option, value, opts, schema) do
          {:error, _reason} = error -> error
          {:ok, opts} -> parse(rest, schema, opts, args)
        end

      {:arg, arg, rest} ->
        parse(rest, schema, opts, [arg | args])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_option(option, value, opts, schema) do
    action = CliOptions.Schema.action(option, schema.schema)

    value =
      maybe_default_value(schema.schema[option][:type], value, schema.schema[option][:default])

    put_option_with_action(action, option, value, opts)
  end

  defp maybe_default_value(:boolean, _value, default), do: default
  defp maybe_default_value(_type, value, _default), do: value

  defp put_option_with_action(:negate, option, value, opts),
    do: put_option_with_action(:set, option, !value, opts)

  defp put_option_with_action(:set, option, [value], opts),
    do: put_option_with_action(:set, option, value, opts)

  defp put_option_with_action(:set, option, value, opts) do
    case opts[option] do
      nil -> {:ok, Keyword.put(opts, option, value)}
      current -> {:error, "option #{inspect(option)} has already been set with #{current}"}
    end
  end

  defp put_option_with_action(:append, option, value, opts) when is_list(value) do
    {:ok, Keyword.update(opts, option, value, fn existing_value -> existing_value ++ value end)}
  end

  defp put_option_with_action(:count, option, _value, opts) do
    {:ok, Keyword.update(opts, option, 1, fn count -> count + 1 end)}
  end

  defp next([], _schema), do: nil

  # if it starts with -- or - it must be an option
  defp next(["--" <> option | rest], schema), do: parse_option(option, :long, rest, schema)

  defp next(["-" <> option_alias | rest], schema),
    do: parse_option_alias(option_alias, rest, schema)

  # in any other case it must be an arg
  defp next([arg | rest], _schema), do: {:arg, arg, rest}

  defp parse_option_alias(option, rest, schema) do
    with {:ok, option} <- validate_option_alias_length(option) do
      parse_option(option, :short, rest, schema)
    end
  end

  defp parse_option(cli_option, short_or_long, rest, schema) do
    with {:ok, option, opts} <-
           CliOptions.Schema.ensure_valid_option(cli_option, short_or_long, schema),
         {:ok, args, rest} <- fetch_option_args(option, opts, rest, schema) do
      if deprecation_message = Keyword.get(opts, :deprecated) do
        IO.warn(
          "#{render_option(cli_option, short_or_long)} is deprecated, " <> deprecation_message
        )
      end

      {:option, option, maybe_split(args, opts[:separator]), rest}
    end
  end

  defp maybe_split(value, nil), do: value
  defp maybe_split([value], separator), do: String.split(value, separator)

  defp render_option(option, :short), do: "-" <> option
  defp render_option(option, :long), do: "--" <> option

  defp fetch_option_args(option, opts, rest, schema) do
    # TODO: currently we handle only one item per option, we can extend it with
    # min max args support like clap
    expected_args = CliOptions.Schema.expected_args(opts)

    {args, rest} = next_args_greedily(rest, expected_args, [], schema)

    # here we take the min with 1 since in case of multiple args
    # the argument may be passed again later
    #
    # for example for a --foo with min_args 2 we could have
    # * --foo n1 n2
    # * --foo n1 --foo n2
    #
    # the final check of the min args validation will happen once
    # we have collected all values
    min_args = min(1, expected_args)

    if args_length(args) < min_args do
      {:error, "#{inspect(option)} expected at least #{min_args} arguments"}
    else
      {:ok, args, rest}
    end
  end

  defp args_length(nil), do: 0
  defp args_length(args), do: length(args)

  # read args from rest greedily
  # it stops parsing when
  #
  # * the rest is empty
  # * a defined option is encountered (checked against schema)
  # * max args have been read
  #
  # returns the read args and the remaining args in rest
  defp next_args_greedily(rest, 0, _args, _schema), do: {nil, rest}

  defp next_args_greedily([], _max, args, _schema), do: {Enum.reverse(args), []}

  defp next_args_greedily(rest, max, args, _schema) when length(args) == max,
    do: {Enum.reverse(args), rest}

  defp next_args_greedily([arg | _other] = rest, max, args, schema) do
    if is_defined_option?(arg, schema) do
      {Enum.reverse(args), rest}
    else
      next_args_greedily(tl(rest), max, [arg | args], schema)
    end
  end

  # Check if a string is a defined option in the schema
  # This allows values like "-10", "-x", "-fgd*&" to be treated as values
  # unless they are actually defined as options in the schema
  defp is_defined_option?("--" <> long_name, schema) do
    Map.has_key?(schema.long_mappings, long_name)
  end

  defp is_defined_option?("-" <> short_name, schema) when byte_size(short_name) == 1 do
    Map.has_key?(schema.short_mappings, short_name)
  end

  defp is_defined_option?(_arg, _schema), do: false

  defp validate_option_alias_length(option_alias) do
    case String.length(option_alias) do
      1 ->
        {:ok, option_alias}

      _other ->
        {:error, "an option alias must be one character long, got: #{inspect(option_alias)}"}
    end
  end

  defp maybe_append_env_values(opts, schema) do
    args_from_env =
      schema.schema
      |> Enum.reject(fn {_key, opts} -> is_nil(opts[:env]) end)
      |> Enum.reject(fn {key, _opts} -> Keyword.has_key?(opts, key) end)
      |> Enum.map(fn {_key, opts} -> maybe_read_env(opts) end)
      |> List.flatten()

    with {:ok, env_opts, []} <- parse(args_from_env, schema, [], []) do
      {:ok, Keyword.merge(opts, env_opts)}
    end
  end

  defp maybe_read_env(opts) do
    env = System.get_env(String.upcase(opts[:env]))

    cond do
      is_nil(env) ->
        []

      opts[:type] == :boolean and truthy?(env) ->
        ["--" <> opts[:long]]

      opts[:type] == :boolean ->
        []

      true ->
        ["--" <> opts[:long], env]
    end
  end

  defp truthy?(value), do: String.downcase(value) in ["1", "true"]
end
