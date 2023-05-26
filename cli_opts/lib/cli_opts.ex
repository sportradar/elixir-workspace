defmodule CliOpts do
  @moduledoc """
  Documentation for `CliOpts`.
  """

  def validate(argv, opts) do
    {argv, task_argv} = split_argv(argv)

    {parsed, argv} = OptionParser.parse!(argv, strict: switches(opts), aliases: aliases(opts))

    with {:ok, args} <- check_required(parsed, opts),
         args <- set_defaults(args, opts) do
      {args, argv, task_argv}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp switches(opts) do
    opts
    |> Enum.map(fn {key, config} -> {key, switch_type(config)} end)
    |> Keyword.new()
  end

  defp switch_type(config) do
    type = Keyword.fetch!(config, :type)

    case config[:keep] do
      true -> [type, :keep]
      _other -> type
    end
  end

  defp aliases(opts) do
    opts
    |> Enum.map(fn {key, config} -> {config[:alias], key} end)
    |> Enum.filter(fn {alias, _key} -> alias != nil end)
    |> Keyword.new()
  end

  defp split_argv(argv) do
    case Enum.find_index(argv, fn x -> x == "--" end) do
      nil -> {argv, []}
      index -> {Enum.slice(argv, 0..(index - 1)), Enum.slice(argv, (index + 1)..-1//1)}
    end
  end

  defp check_required(args, opts) do
    opts
    |> Enum.filter(fn {_key, opts} -> Keyword.get(opts, :required, false) == true end)
    |> Enum.reduce([], fn {key, _opts}, acc ->
      case Keyword.has_key?(args, key) do
        true -> acc
        false -> [key | acc]
      end
    end)
    |> then(fn missing ->
      case missing do
        [] ->
          {:ok, args}

        missing ->
          {:error, "the following required options were not provided #{inspect(missing)}"}
      end
    end)
  end

  defp set_defaults(args, opts) do
    Enum.reduce(opts, args, fn {key, key_opts}, acc ->
      case key_opts[:default] do
        nil -> acc
        value -> Keyword.put_new(acc, key, value)
      end
    end)
  end
end
