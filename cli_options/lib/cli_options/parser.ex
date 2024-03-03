defmodule CliOptions.Parser do
  @moduledoc false

  @spec parse(argv :: [String.t()], schema :: keyword()) ::
          {:ok, keyword()} | {:error, String.t()}
  def parse(argv, schema) do
    # we split the extra args first (anything after the first --) and then
    # parse the remaining
    {remaining_argv, extra} = split_extra(argv)

    with {:ok, schema} <- validate_schema(schema),
         {:ok, opts, args} <- parse(remaining_argv, schema, [], []) do
      {:ok, CliOptions.Options.new(argv, schema[:schema], opts, args, extra)}
    end
  end

  # TODO: proper schema validation - move to separate module
  defp validate_schema(schema) do
    aliases =
      Enum.filter(schema, fn {_option, opts} -> opts[:alias] != nil end)
      |> Enum.map(fn {option, opts} -> {opts[:alias], option} end)
      |> Enum.into([])

    {:ok, aliases: aliases, schema: schema}
  end

  # TODO: tests
  #  - with and without separator
  #  - with multiple separators
  #  - without options but with separator 
  defp split_extra(argv), do: split_extra(argv, [])

  defp split_extra([], argv), do: {Enum.reverse(argv), []}
  defp split_extra(["--" | rest], argv), do: {Enum.reverse(argv), rest}
  defp split_extra([arg | rest], argv), do: split_extra(rest, [arg | argv])

  defp parse(argv, schema, opts, args) do
    case next(argv, schema) do
      nil ->
        {:ok, opts, Enum.reverse(args)}

      {:option, option, value, rest} ->
        parse(rest, schema, [{option, value} | opts], args)

      {:arg, arg, rest} ->
        parse(rest, schema, opts, [arg | args])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp next([], schema), do: nil

  # if it starts with -- or - it must be an option 
  defp next(["--" <> option | rest], schema), do: parse_option(option, rest, schema)

  defp next(["-" <> option_alias | rest], schema),
    do: parse_option_alias(option_alias, rest, schema)

  # in any other case it must be an arg
  defp next([arg | rest], _schema), do: {:arg, arg, rest}

  defp parse_option_alias(option_alias, rest, schema) do
    with {:ok, option_alias} <- validate_option_alias_length(option_alias),
         {:ok, option} <- validate_alias(option_alias, schema) do
      parse_option(option, rest, schema)
    end
  end

  defp parse_option(option, rest, schema) do
    with {:ok, option, opts} <- validate_option(option, schema[:schema]),
         {:ok, args, rest} <- validate_option_args(option, opts, rest) do
      {:option, option, args, rest}
    end
  end

  defp validate_option_args(option, opts, rest) do
    # TODO: read maximum from opts
    {args, rest} = next_args_greedy(rest, 1, [])

    # TODO: min args is not the minimum number of expected occurrences of the
    # option since it may be defined later. It should be either 1 for types
    # expecting an argument or 0 for booleans / counts
    min_args = 1

    if length(args) < min_args do
      {:error, "#{inspect(option)} expected one argument"}
    else
      {:ok, args, rest}
    end
  end

  # read args from rest greedily
  # it stops parsing when
  #
  # * the rest is empty
  # * an option or alias is ecountered
  # * max args have been read
  #
  # returns the read args and the remaining args in rest
  defp next_args_greedy([], max, args), do: {Enum.reverse(args), []}

  defp next_args_greedy(rest, max, args) when length(args) == max, do: {Enum.reverse(args), rest}

  defp next_args_greedy(["-" <> _arg | _other] = rest, _max, args), do: {Enum.reverse(args), rest}

  defp next_args_greedy([arg | rest], max, args), do: next_args_greedy(rest, max, [arg | args])

  defp validate_option_alias_length(option_alias) do
    case String.length(option_alias) do
      1 ->
        {:ok, option_alias}

      _other ->
        {:error, "an option alias must be one character long, got: #{inspect(option_alias)}"}
    end
  end

  defp validate_alias(option_alias, schema) do
    case Keyword.get(schema[:aliases], option_alias) do
      nil -> {:error, "invalid option alias #{inspect(option_alias)}"}
      option -> {:ok, option}
    end
  end

  defp validate_option(option, schema) do
    option = String.to_atom(option)

    case Keyword.get(schema, option) do
      nil -> {:error, "invalid option #{inspect(option)}"}
      opts -> {:ok, option, opts}
    end
  end
end
