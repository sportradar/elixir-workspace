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
      The assets path with respect to the current working directory.
      This is where all template assets should be added. By convention
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
    templates_path = opts[:templates_path] || default_templates_path()
    module = Path.join(templates_path, opts[:name]) |> Macro.camelize()

    relative_assets_to_templates_path =
      Cascade.Utils.relative_to(
        Path.expand(opts[:assets_path]),
        Path.expand(Path.join("lib", templates_path))
      )

    opts =
      opts
      |> Keyword.put(:templates_path, templates_path)
      |> Keyword.put(:module, module)
      |> Keyword.put(:relative_assets_to_templates_path, relative_assets_to_templates_path)

    {:ok, opts}
  end

  @impl Cascade.Template
  def destination_path(asset_path, root_path, opts) do
    case asset_path do
      "README.md" ->
        Path.join([root_path, opts[:assets_path], opts[:name], asset_path])

      "template.ex" ->
        Path.join([root_path, "lib", opts[:templates_path], "#{opts[:name]}.ex"])
    end
  end

  defp default_templates_path do
    File.cwd!()
    |> Path.basename()
    |> Path.join("templates")
  end
end
