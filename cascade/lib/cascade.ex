defmodule Cascade do
  @moduledoc """
  Generate code from templates.
  """

  @doc """
  Returns all available templates.

  All modules implementing the `Cascade.Template` behaviour will be returned.
  """
  @spec templates() :: keyword()
  def templates do
    template_modules = Cascade.Utils.modules_implementing_behaviour(Cascade.Template)

    Enum.map(template_modules, fn module -> {module.name(), module} end)
  end

  @doc """
  Generate the code associated to the given template `name`.

  * `root_path` is expected to be the root directory under which the template
  will be generated.
  * `args_or_opts` can be an arbitrary keyword list with the template options or
  a list of command line arguments passed to the `mix cascade` task. In the latter
  case the arguments will be validated using the template's `c:Cascade.Template.args_schema/0`.

  ## Options

    * `:force` - if set existing files are overwritten without asking, defaults
    to `false`.
  """
  @spec generate(
          name :: atom(),
          root_path :: String.t(),
          args_or_opts :: keyword() | [String.t()],
          opts :: keyword()
        ) ::
          {:error, String.t()} | :ok
  def generate(name, root_path, args_or_opts \\ [], opts \\ []) do
    with {:ok, template} <- template_from_name(name),
         {:ok, template_opts} <- validate_template_opts(template, args_or_opts) do
      Cascade.Template.generate(template, root_path, template_opts, opts)
    end
  end

  defp template_from_name(name) when is_atom(name) do
    templates = templates()

    case templates[name] do
      nil -> {:error, "no template #{inspect(name)} found"}
      module -> {:ok, module}
    end
  end

  # an empty list is considered command line arguments, in both cases the
  # defaults and required options of the template's schema are applied
  defp validate_template_opts(template, args_or_opts) do
    args_schema = template.args_schema()

    result =
      if args_or_opts != [] and Keyword.keyword?(args_or_opts) do
        with_schema_defaults(args_or_opts, args_schema)
      else
        with {:ok, {opts, _args, _extra}} <- CliOptions.parse(args_or_opts, args_schema) do
          {:ok, opts}
        end
      end

    with {:ok, opts} <- result do
      template.validate_cli_opts(opts)
    end
  end

  defp with_schema_defaults(opts, args_schema) do
    schema = CliOptions.Schema.new!(args_schema).schema

    missing =
      for {key, key_schema} <- schema,
          key_schema[:required],
          not Keyword.has_key?(opts, key),
          do: key

    defaults =
      for {key, key_schema} <- schema,
          Keyword.has_key?(key_schema, :default),
          not Keyword.has_key?(opts, key),
          do: {key, key_schema[:default]}

    case missing do
      [] -> {:ok, opts ++ defaults}
      [key | _rest] -> {:error, "option #{inspect(key)} is required"}
    end
  end
end
