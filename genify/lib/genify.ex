defmodule Genify do
  @moduledoc """
  Generate code from templates.
  """

  def generate(name, templates_path, opts \\ []) do
    path = Path.join(templates_path, name)

    with {:ok, path} <- validate_file_exists(path, "template path #{path} does not exist"),
         {:ok, template_config} <- read_template_config(path),
         {:ok, template_module} <- validate_template_module(template_config),
         {:ok, template_files} <- template_files(path),
         {:ok, opts} <- validate_template_cli_opts(template_config, opts),
         {:ok, opts} <- template_module.post_process_cli_opts(opts) do
      generate_template(path, template_files, template_config, opts)
    end
  end

  defp read_template_config(path) do
    config_path = Path.join(path, "config.exs")

    with {:ok, config_path} <-
           validate_file_exists(config_path, "template config #{config_path} does not exist") do
      {template_config, _bindings} = Code.eval_file(config_path)
      {:ok, template_config}
    end
  end

  defp validate_template_module(config) do
    # TODO: verify that it implements the proper behaviour
    case config[:module] do
      nil -> {:error, "no template module defined in template config"}
      module -> {:ok, module}
    end
  end

  defp template_files(path) do
    assets_path = Path.join(path, "assets")

    with {:ok, assets_path} <-
           validate_file_exists(assets_path, "assets path #{assets_path} does not exist") do
      files = Path.wildcard(Path.join(assets_path, "**"))

      case files do
        [] -> {:error, "no template files detected under #{assets_path}"}
        files -> {:ok, files}
      end
    end
  end

  defp validate_file_exists(path, error_message) do
    case File.exists?(path) do
      true -> {:ok, path}
      false -> {:error, error_message}
    end
  end

  defp validate_template_cli_opts(template_config, args) do
    args_schema = Keyword.get(template_config, :args, [])

    {:ok, %{parsed: args}} = CliOpts.parse(args, args_schema)
    {:ok, args}
  end

  defp generate_template(path, template_files, template_config, opts) do
    module = Keyword.fetch!(template_config, :module)
    Code.ensure_loaded!(module)

    for file <- template_files, relative_path = relative_to_assets_path(file, path) do
      source_path = file
      destination_path = module.destination_path(relative_path, template_config, opts)

      body =
        source_path
        |> EEx.eval_file(opts)
        |> maybe_format(destination_path)

      IO.puts("generating #{file} - #{relative_path}")
      IO.puts("destination path - #{destination_path}")
      Mix.Generator.create_file(destination_path, body, force: true)
    end
  end

  defp relative_to_assets_path(path, template_path) do
    Path.relative_to(path, Path.join(template_path, "assets"))
  end

  @elixir_extensions [".ex", ".exs", ".heex"]

  defp maybe_format(body, path) do
    extension = Path.extname(path)

    case extension in @elixir_extensions do
      true -> Code.format_string!(body)
      false -> body
    end
  end
end
