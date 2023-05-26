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

  def docs(opts) do
    opts
    |> Enum.reduce([], &maybe_option_doc/2)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp maybe_option_doc({key, schema}, acc) do
    if schema[:doc] == false do
      acc
    else
      option_doc({key, schema}, acc)
    end
  end

  defp option_doc({key, schema}, acc) do
    doc =
      """
      * `#{key_doc(key, schema)}` - #{key_body_doc(schema)}
      """
      |> String.trim_trailing()

    [doc | acc]
  end

  defp key_doc(key, schema) do
    "--#{key}#{maybe_alias(schema)}"
    |> maybe_optional(schema)
    |> maybe_repeating(schema)
  end

  defp maybe_alias(schema) do
    case schema[:alias] do
      nil -> ""
      alias -> ", -#{alias}"
    end
  end

  defp maybe_optional(key, schema) do
    case schema[:required] do
      true -> key
      _ -> "[#{key}]"
    end
  end

  defp maybe_repeating(key, schema) do
    case schema[:keep] do
      true -> "#{key}..."
      _ -> key
    end
  end

  defp key_body_doc(schema) do
    "#{schema[:doc]}#{maybe_default(schema)}"
  end

  defp maybe_default(schema) do
    case schema[:default] do
      nil -> ""
      default -> " [default: `#{default}`]"
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
