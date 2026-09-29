defmodule Cascade.Templates.Template do
  @args_schema [
    name: [
      type: :string,
      doc: "The template name.",
      required: true
    ],
    assets_path: [
      type: :string,
      doc: """
      The assets path relative to the root path. This is where all
      template assets should be added. By convention
      it defaults to a `templates` folder at the same level as your
      `lib` folder.
      """,
      required: false,
      default: "templates"
    ],
    templates_path: [
      type: :string,
      doc: """
      The path under the `lib` folder where templates are stored. If not
      set defaults to `{app_name}/templates`.
      """
    ]
  ]

  @shortdoc "Generates a new template"

  @moduledoc """
  Generates a new template.

  ## Command line options

  #{CliOptions.docs(@args_schema)}
  """
  use Cascade.Template

  @assets_path Path.expand("../../../templates/template", __DIR__)

  @impl Cascade.Template
  def assets_path, do: @assets_path

  # Generates a cascade template
  @impl Cascade.Template
  def name, do: :template

  @impl Cascade.Template
  def args_schema, do: @args_schema

  @impl Cascade.Template
  def validate_cli_opts(opts) do
    with :ok <- validate_name(opts[:name]),
         :ok <- validate_assets_path(opts[:assets_path]),
         {:ok, templates_path} <- templates_path(opts[:templates_path]),
         {:ok, module} <- module(templates_path, opts[:name]) do
      relative_assets_to_templates_path =
        Path.relative_to(
          Path.expand(opts[:assets_path]),
          Path.expand(Path.join("lib", templates_path)),
          force: true
        )

      opts =
        opts
        |> Keyword.put(:templates_path, templates_path)
        |> Keyword.put(:module, module)
        |> Keyword.put(:relative_assets_to_templates_path, relative_assets_to_templates_path)

      {:ok, opts}
    end
  end

  # the name is used in paths and module names
  defp validate_name(name) do
    if name =~ ~r/\A[a-z][a-z0-9_]*\z/ do
      :ok
    else
      {:error,
       "invalid template name #{inspect(name)}, it must start with a lowercase letter " <>
         "and contain only lowercase letters, numbers and underscores"}
    end
  end

  defp validate_assets_path(assets_path) do
    case Path.type(assets_path) do
      :relative -> :ok
      _other -> {:error, "--assets-path must be relative to the root path, got: #{assets_path}"}
    end
  end

  defp templates_path(nil) do
    case Mix.Project.config()[:app] do
      nil -> {:error, "could not detect the application name, please set --templates-path"}
      app -> {:ok, Path.join(Atom.to_string(app), "templates")}
    end
  end

  defp templates_path(templates_path), do: {:ok, templates_path}

  defp module(templates_path, name) do
    module = Path.join(templates_path, name) |> Macro.camelize()

    if module =~ ~r/\A[A-Z]\w*(\.[A-Z]\w*)*\z/ do
      {:ok, module}
    else
      {:error, "invalid module name #{inspect(module)}, please check the --templates-path"}
    end
  end

  @impl Cascade.Template
  def destination_path(asset_path, root_path, opts) do
    case asset_path do
      "PLACEHOLDER.md" ->
        Path.join([root_path, opts[:assets_path], opts[:name], asset_path])

      "template.ex" ->
        Path.join([root_path, "lib", opts[:templates_path], "#{opts[:name]}.ex"])
    end
  end
end
