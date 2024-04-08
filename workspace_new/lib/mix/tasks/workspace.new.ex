defmodule Mix.Tasks.Workspace.New do
  @shortdoc "Creates a new workspace project"

  @moduledoc """
  Creates a new workspace project.

  It expects the path of the project as an argument.

      $ mix workspace.new PATH [--module MODULE] [--app APP]

  A workspace at the given `PATH` will be created. The The
  application name and module name will be retrieved
  from the path, unless `--module` or `--app` is given.

  ## Options

    * `--app` - the name of the workspace

    * `--module` - the name of the base mix workspace module in
      the generated skeleton

  In most cases you will not need to pass any options.

  ## Examples

      $ mix workspace.new my_workspace

  Would generate the following structure:

  ```text
  my_workspace
  ├── .formatter.exs
  ├── .gitignore
  ├── .workspace.exs
  ├── README.md
  └── mix.exs
  ```

  You can now add normal mix projects within your workspace
  using the `mix new` command and update your workspace config
  by editing the `.workspace.exs` configuration file.

  For more details check the `Workspace` docs.
  """

  use Mix.Task

  import Mix.Generator

  @switches [
    app: :string,
    module: :string
  ]

  root_path = Path.expand("../../../template", __DIR__)

  @template_files ["README.md", ".formatter.exs", ".gitignore", "mix.exs", ".workspace.exs"]
                  |> Enum.map(fn filename ->
                    {filename, File.read!(Path.join(root_path, filename))}
                  end)
                  |> Enum.into(%{})

  @impl true
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    case argv do
      [] ->
        Mix.raise("Expected PATH to be given, please use `mix workspace.new PATH`")

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        check_application_name!(app, !opts[:app])

        mod = opts[:module] || Macro.camelize(app)
        check_mod_name_validity!(mod)
        check_mod_name_availability!(mod)

        unless path == "." do
          if File.exists?(path) do
            Mix.raise(
              "Directory #{path} already exists, please select another directory for your workspace"
            )
          end

          File.mkdir_p!(path)
        end

        File.cd!(path, fn ->
          generate(app, mod, path)
        end)
    end
  end

  defp check_application_name!(name, inferred?) do
    unless name =~ ~r/^[a-z][a-z0-9_]*$/ do
      Mix.raise(
        "Application name must start with a lowercase ASCII letter, followed by " <>
          "lowercase ASCII letters, numbers, or underscores, got: #{inspect(name)}" <>
          if inferred? do
            ". The application name is inferred from the path, if you'd like to " <>
              "explicitly name the application then use the \"--app APP\" option"
          else
            ""
          end
      )
    end
  end

  defp check_mod_name_validity!(name) do
    unless name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/ do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp check_mod_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  defp generate(app, mod, _path) do
    bindings = [
      app: app,
      mod: mod,
      version: get_version(System.version())
    ]

    for {file, content} <- @template_files do
      create_file(file, template(content, bindings))
    end
  end

  defp template(content, bindings) do
    EEx.eval_string(content, bindings)
  end

  defp get_version(version) do
    {:ok, version} = Version.parse(version)

    "#{version.major}.#{version.minor}"
  end
end
