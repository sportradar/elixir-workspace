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

  @external_resource "template"

  use Mix.Task

  import Mix.Generator

  @switches [
    app: :string,
    module: :string
  ]

  root_path = Path.expand("../../../template", __DIR__)
  template_files = ["README.md", ".formatter.exs", ".gitignore", "mix.exs", ".workspace.exs"]

  for file <- template_files do
    @external_resource Path.join(root_path, file)
  end

  @template_files template_files
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

        if path != "." do
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
    if !(name =~ ~r/^[a-z][a-z0-9_]*$/) do
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
    if !(name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
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

  defp generate(app, mod, path) do
    bindings = [
      app: app,
      mod: mod,
      version: get_version(System.version())
    ]

    for {file, content} <- @template_files do
      create_file(file, template(content, bindings))
    end

    """

    You workspace was created successfully. You can use `mix` to add
    workspace projects within it and the `workspace.*` commands to
    work with it:

        cd #{path}
        mix deps.get && mix compile

        # you can add as many internal projects as you wish
        # at any subfolder of #{path}
        mix new package_a
        mix new package_b

        # test all projects
        mix workspace.run -t test

    For more details on a specific command run `mix help command`. You
    can list all workspace commands with:

        mix help --search workspace
    """
    |> String.trim_trailing()
    |> Mix.shell().info()
  end

  defp template(content, bindings) do
    EEx.eval_string(content, bindings)
  end

  defp get_version(version) do
    {:ok, version} = Version.parse(version)

    "#{version.major}.#{version.minor}"
  end
end
