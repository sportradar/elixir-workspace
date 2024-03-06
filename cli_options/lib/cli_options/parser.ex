defmodule CliOptions.Parser do
  @moduledoc false

  @spec parse(argv :: [String.t()], schema :: keyword()) ::
          {:ok, keyword()} | {:error, String.t()}
  def parse(argv, schema) do
    # we split the extra args first (anything after the first --) and then
    # parse the remaining
    {remaining_argv, extra} = split_extra(argv)

    with {:ok, schema} <- CliOptions.Schema.validate(schema),
         {:ok, opts, args} <- parse(remaining_argv, schema, [], []),
         {:ok, opts} <- CliOptions.Schema.validate(opts, schema) do
      {:ok, CliOptions.Options.new(argv, schema.schema, opts, args, extra)}
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
    put_option_with_action(action, option, value, opts)
  end

  defp put_option_with_action(:set_true, option, _value, opts),
    do: put_option_with_action(:set, option, true, opts)

  defp put_option_with_action(:set_false, option, _value, opts),
    do: put_option_with_action(:set, option, false, opts)

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
  defp next(["--" <> option | rest], schema), do: parse_option(option, rest, schema)

  defp next(["-" <> option_alias | rest], schema),
    do: parse_option_alias(option_alias, rest, schema)

  # in any other case it must be an arg
  defp next([arg | rest], _schema), do: {:arg, arg, rest}

  defp parse_option_alias(option, rest, schema) do
    with {:ok, option} <- validate_option_alias_length(option) do
      parse_option(option, rest, schema)
    end
  end

  defp parse_option(option, rest, schema) do
    with {:ok, option, opts} <- CliOptions.Schema.ensure_valid_option(option, schema),
         {:ok, args, rest} <- fetch_option_args(option, opts, rest) do
      {:option, option, args, rest}
    end
  end

  defp fetch_option_args(option, opts, rest) do
    # TODO: currently we handle only one item per option, we can extend it with
    # min max args suppport like clap
    expected_args = CliOptions.Schema.expected_args(opts)

    {args, rest} = next_args_greedily(rest, expected_args, [])

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
  # * an option or alias is ecountered
  # * max args have been read
  #
  # returns the read args and the remaining args in rest
  defp next_args_greedily(rest, 0, _args), do: {nil, rest}

  defp next_args_greedily([], _max, args), do: {Enum.reverse(args), []}

  defp next_args_greedily(rest, max, args) when length(args) == max, do: {Enum.reverse(args), rest}

  defp next_args_greedily(["-" <> _arg | _other] = rest, _max, args), do: {Enum.reverse(args), rest}

  defp next_args_greedily([arg | rest], max, args), do: next_args_greedily(rest, max, [arg | args])

  defp validate_option_alias_length(option_alias) do
    case String.length(option_alias) do
      1 ->
        {:ok, option_alias}

      _other ->
        {:error, "an option alias must be one character long, got: #{inspect(option_alias)}"}
    end
  end
end
