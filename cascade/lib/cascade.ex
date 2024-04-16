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

  `root_path` is expected to be the root directory under which the template
  will be generated. `opts` can be an arbitrary keyword list corresponding
  to the command line options passed to the `mix cascade` task.
  """
  @spec generate(name :: atom(), root_path :: String.t(), opts :: keyword()) ::
          {:error, String.t()} | :ok
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

    with {:ok, {opts, _args, _extra}} <- CliOptions.parse(args, args_schema) do
      template.validate_cli_opts(opts)
    end
  end
end
