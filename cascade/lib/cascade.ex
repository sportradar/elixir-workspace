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

  def generate(name, root_path, opts \\ []) do
    with {:ok, template} <- template_from_name(name),
         {:ok, opts} <- validate_template_cli_opts(template, opts) do
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

  defp validate_template_cli_opts(template, args) do
    args_schema = template.args_schema()

    with {:ok, %{parsed: args}} <- CliOpts.parse(args, args_schema) do
      template.validate_cli_opts(args)
    end
  end
end
