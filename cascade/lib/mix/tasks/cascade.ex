defmodule Mix.Tasks.Cascade do
  use Mix.Task

  @args_schema [
    root: [
      type: :string,
      doc: """
      The root path under which the template will be generated.

        - If it is not set it defaults to the current working directory.
        - If it is a relative path is is expanded with respect to the
        current working directory.
        - If is is an absolute path it is used unchanged.
      """
    ]
  ]

  @shortdoc "Generates code from a template"

  @moduledoc """
  Generates code from the given template.

  It expects the template name as argument.

      $ mix cascade template_name [--root PATH] -- [...]

  The extra command line arguments depend on the template. You can
  list all available templates by running:

      $ mix cascade.list

  You can get detailed docs for a specific template by running:

      $ mix cascade.help template_name

  ## Options

  #{CliOpts.docs(@args_schema)}
  """

  @impl Mix.Task
  def run(argv) do
    %{parsed: opts, args: args, extra: extra} = CliOpts.parse!(argv, @args_schema)

    case args do
      [template] ->
        template = String.to_atom(template)
        root_path = Path.expand(opts[:root] || File.cwd!())

        case Cascade.generate(template, root_path, extra) do
          {:error, reason} -> Mix.raise(reason)
          _other -> :ok
        end

      _other ->
        Mix.raise(
          "expected a single template to be given, please use \"mix cascade template_name\""
        )
    end
  end
end
