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
  """
  @spec generate(
          name :: atom(),
          root_path :: String.t(),
          args_or_opts :: keyword() | [String.t()]
        ) ::
          {:error, String.t()} | :ok
  def generate(name, root_path, args_or_opts \\ []) do
    with {:ok, template} <- template_from_name(name),
         {:ok, opts} <- validate_template_opts(template, args_or_opts) do
      Cascade.Template.generate(template, root_path, opts)
    end
  end

  defp template_from_name(name) when is_atom(name) do
    templates = templates()

    case templates[name] do
      nil -> {:error, "no template #{inspect(name)} found"}
      module -> {:ok, module}
    end
  end

  defp validate_template_opts(template, args_or_opts) do
    if Keyword.keyword?(args_or_opts) do
      template.validate_cli_opts(args_or_opts)
    else
      args_schema = template.args_schema()

      with {:ok, {opts, _args, _extra}} <- CliOptions.parse(args_or_opts, args_schema) do
        template.validate_cli_opts(opts)
      end
    end
  end
end
