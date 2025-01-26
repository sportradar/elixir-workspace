defmodule Workspace.Test do
  @moduledoc """
  Convenience helper functions for workspace tests.
  """

  import ExUnit.Assertions

  def create_workspace(path, config, fixture_or_projects, opts \\ [])

  def create_workspace(path, config, fixture, opts) when is_atom(fixture) do
    create_workspace(path, config, fixture(fixture), opts)
  end

  def create_workspace(path, config, projects, opts) do
    workspace_path = Path.expand(path)

    File.mkdir_p!(workspace_path)

    if File.ls!(workspace_path) != [] do
      raise ArgumentError,
            "cannot create a workspace in a non empty path, #{workspace_path} is not empty"
    end

    # write the workspace mix.exs and .workspace.exs
    File.write!(
      Path.join(workspace_path, "mix.exs"),
      """
      defmodule TestWorkspace.MixProject do
        use Mix.Project
        def project do
          [
            app: :test_workspace,
            elixir: "~> 1.14",
            start_permanent: Mix.env() == :prod,
            elixirc_paths: [],
            workspace: #{inspect(config)}
          ]
        end
      end\
      """
      |> Code.format_string!()
    )

    File.write!(Path.join(workspace_path, ".workspace.exs"), "[]")

    # write the projects
    for {app, path, project_config} <- projects do
      create_mix_project(workspace_path, app, path, project_config, opts)
    end
  end

  @doc """
  Creates a mix project fixture under the given workspace path.

  The `path` is expected to be the relative path with respect to the `workspace_path` where
  the project will be located.

  You can pass either a project config which will be merged with some default settings
  and persisted, or directly the contents of the mix file. Notice that in the latter case
  `app` is not used.

  For example by calling:

      create_mix_project("path/to/workspace", :foo, "packages/foo", [description: "The foo project"])

  will write the following to `path/to/workspace/packages/foo/mix.exs`:
      
      defmodule Foo.MixProject do
        use Mix.Project

        def project do
          [
            app: :foo,
            elixir: "~> 1.14",
            start_permanent: false,
            elixirc_paths: [],
            description: "The foo project"
          ]
        end
      end

  ## Options

  * `:formatter` - Whether to add a default `.formatter.exs`, defaults to `true`
  * `:lib_folder` - Whether to create an empty `lib` sub folder, defaults to `true`
  """
  def create_mix_project(workspace_path, app, path, config_or_binary, opts \\ []) do
    if Path.type(path) != :relative do
      raise ArgumentError, "path must be relative, got: #{path}"
    end

    path = Path.join(workspace_path, path)
    File.mkdir_p!(path)

    mix_content = mix_file(app, config_or_binary, opts)

    # add the project's mix.exs
    File.write!(Path.join(path, "mix.exs"), mix_content)

    # add the formatter if needed
    if Keyword.get(opts, :formatter, true) do
      File.write!(
        Path.join(path, ".formatter.exs"),
        """
        [
          inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
        ]
        """
      )
    end

    # create the lib folder in case any test needs to write a file
    if Keyword.get(opts, :lib_folder, true) do
      File.mkdir_p!(Path.join(path, "lib"))
    end
  end

  defp mix_file(_app, config, _opts) when is_binary(config), do: config

  defp mix_file(app, config, opts) do
    module = Macro.camelize("#{app}") <> ".MixProject"

    config =
      Keyword.merge(
        [
          app: app,
          elixir: "~> 1.14",
          start_permanent: Mix.env() == :prod,
          elixirc_paths: []
        ],
        config
      )
      |> Keyword.merge(opts[app] || [])

    """
    defmodule #{module} do
      use Mix.Project
      def project do
        #{inspect(config)}
      end
    end
    """
    |> Code.format_string!()
    |> Kernel.++(["\n"])
  end

  @doc """
  Runs the given `test_fn` in a temporary workspace under the given `path`.

  Projects is expected to be a list of tuples of the form `{name, path, config}`.
  TODO: document default fixtures

  Config is the project config which will be merged with the default:

  ```elixir
  [
    app: name,
    version: "0.1.0",
    elixir: "~> 1.14",
    start_permanent: Mix.env() == :prod,
  ]
  ```

  The fixture directory is removed at the end of the invocation. Use `create_workspace/4`
  directly if you wish to keep it for multiple tests.
  """
  def with_workspace(path, config, fixture_or_projects, test_fn, opts \\ []) do
    config = Keyword.merge(config, type: :workspace)

    fixture_path = Path.expand(path)
    create_workspace(fixture_path, config, fixture_or_projects, opts[:projects] || [])

    in_fixture(fixture_path, fn ->
      maybe_cd!(fixture_path, opts[:cd], fn ->
        if opts[:git], do: init_git_project(fixture_path)

        test_fn.()
      end)
    end)
  after
    File.rm_rf!(path)
  end

  @doc """
  Runs the given test function unloading at the end any module or package initialized
  from within the given `path`.

  `path` is considered to be the fixture path. Any module that will be loaded during the
  `test_fn` execution will be purged and deleted at the end.

  It is advised to use this on any test that requires a fixture, in order to avoid
  warnings about redefining packages.
  """
  def in_fixture(path, test_fn) do
    path = Path.expand(path)
    initial_path = :code.get_path()
    previous = :code.all_loaded()

    try do
      test_fn.()
    after
      :code.set_path(initial_path)

      for {mod, file} <- :code.all_loaded() -- previous,
          file == [] or
            (is_list(file) and List.starts_with?(file, String.to_charlist(path))) do
        # IO.puts("purging #{mod}")
        :code.purge(mod)
        :code.delete(mod)
        Mix.State.clear_cache()
        # Mix.ProjectStack.clear_stack()
      end
    end
  end

  @type project_fixture :: {atom(), Path.t(), keyword()}

  @doc """
  Generates a **virtual** workspace fixture.

  It expects one of the following:

  * A list of `Workspace.Project` structs.
  * A list of tuples of the form, `{app, path, config}` which will be used for generating
  project fixtures (see `project_fixture/4` for more details)
  * An atom representing a default fixture.

  > #### Virtual fixture {: .warning}
  >
  > Notice that this creates an in-memory virtual fixture. This means that the underlying mix
  > projects do not exist and are not loaded.
  >
  > If you want to test something on an actual project you should use the `with_workspace/5`
  > instead which generates the actual fixtures and loads them in memory.

  ## Options

  * `workspace_path` - The absolute workspace path to which this project belongs.
  If not set defaults to `/usr/local/workspace`.
  """
  @spec workspace_fixture(
          projects_or_fixture :: atom() | [Workspace.Project.t() | project_fixture()],
          opts :: keyword()
        ) :: Workspace.State.t()
  def workspace_fixture(projects_or_fixture, opts \\ [])

  def workspace_fixture(fixture, opts) when is_atom(fixture),
    do: workspace_fixture(fixture(fixture), opts)

  def workspace_fixture(projects, opts) when is_list(projects) do
    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")
    mix_path = Path.join(workspace_path, "mix.exs")

    projects =
      Enum.map(projects, fn project ->
        case project do
          %Workspace.Project{} ->
            project

          {app, path, config} ->
            project_fixture(app, path, config, workspace_path: workspace_path)
        end
      end)

    {:ok, workspace} = Workspace.new(workspace_path, mix_path, [], projects)
    workspace
  end

  @doc """
  Creates a **virtual** fixture for a mix project.

  It expects the `app` name, a `path` relative to the workspace which indicates
  the project's location and a project config.

  Tests using this function can be safely executed in `async` mode.

  ## Options

  * `workspace_path` - The absolute workspace path to which this project belongs.
  If not set defaults to `/usr/local/workspace`.

  ## Examples

      iex> Workspace.Test.project_fixture(:foo, "packages/foo", [description: "the foo package"])
      %Workspace.Project{
        app: :foo,
        module: :"Foo.MixProject",
        config: [description: "the foo package", app: :foo],
        mix_path: "/usr/local/workspace/packages/foo/mix.exs",
        path: "/usr/local/workspace/packages/foo",
        workspace_path: "/usr/local/workspace",
        skip: false,
        status: :undefined,
        root?: nil,
        changes: nil,
        tags: []
      }

  Notice that if `path` is not a relative path an exception will be raised.

  > #### Virtual fixture {: .warning}
  >
  > Notice that this creates an in-memory virtual fixture. This means that the underlying mix
  > project does not exist and is not loaded.
  >
  > If you want to test something on an actual project you should use the `with_workspace/5`
  > instead which generates the actual fixtures and loads them in memory.
  """
  @spec project_fixture(app :: atom(), path :: Path.t(), config :: keyword(), opts :: keyword()) ::
          Workspace.Project.t()
  def project_fixture(app, path, config, opts \\ []) do
    if Path.type(path) != :relative do
      raise ArgumentError, "path must be relative, got: #{path}"
    end

    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")
    project_path = Path.join([workspace_path, path])
    mix_path = Path.join(project_path, "mix.exs")
    module = project_module(app)
    config = Keyword.merge(config, app: app)

    Workspace.Project.new(workspace_path, mix_path, module, config)
  end

  defp project_module(app) do
    (Macro.camelize(Atom.to_string(app)) <> ".MixProject")
    |> String.to_atom()
  end

  defp fixture(:default) do
    [
      {:package_a, "package_a",
       deps: [
         {:package_b, path: "../package_b"},
         {:package_c, path: "../package_c"},
         {:package_d, path: "../package_d"},
         {:ex_doc, "~> 0.32"}
       ],
       package: [maintainers: ["Jack Sparrow"]],
       workspace: [tags: [:shared, {:area, :core}]]},
      {:package_b, "package_b",
       deps: [
         {:package_g, path: "../package_g"},
         {:foo, "~> 1.0"}
       ],
       description: "a dummy project"},
      {:package_c, "package_c",
       deps: [
         {:package_e, path: "../package_e"},
         {:package_f, path: "../package_f"}
       ]},
      {:package_d, "package_d", deps: []},
      {:package_e, "package_e", deps: []},
      {:package_f, "package_f",
       deps: [
         {:package_g, path: "../package_g"}
       ]},
      {:package_g, "package_g", deps: []},
      {:package_h, "package_h",
       deps: [
         {:package_d, path: "../package_d"}
       ]},
      {:package_i, "package_i",
       deps: [
         {:package_j, path: "../package_j"}
       ]},
      {:package_j, "package_j", deps: []},
      {:package_k, "nested/package_k", deps: []}
    ]
  end

  defp maybe_cd!(fixture_path, true, test_fn), do: File.cd!(fixture_path, test_fn)
  defp maybe_cd!(_fixture_path, _cd, test_fn), do: test_fn.()

  def init_git_project(path) do
    File.cd!(path, fn ->
      System.cmd("git", ~w[init])
      System.cmd("git", ~w[symbolic-ref HEAD refs/heads/main])
      System.cmd("git", ~w[add .])
      System.cmd("git", ~w[commit -m "commit"])
    end)
  end

  def modify_project(workspace_path, project_path) do
    path = Path.join(workspace_path, project_path)

    if not File.exists?(path), do: raise(ArgumentError, "invalid project fixture path: #{path}")

    File.touch!(Path.join(path, "lib/file.ex"))
  end

  def commit_changes(path) do
    File.cd!(path, fn ->
      System.cmd("git", ~w[add .])
      System.cmd("git", ~w[commit -m "changes"])
    end)
  end

  @doc """
  Asserts that the captured cli output matches the expected value with respect to 
  the given options.

  This helper assertion function provides some conveniences for working with cli output assertions.

  ## Options

  - `:trim_trailing_newlines` - if set trailing newlines are ignored.
  - `:trim_whitespace` - if set either leading or trailing whitespace is ignored from
  each line of the output.
  - `:trim_leading` - if set leading whitespace is ignored from each line of the output.
  - `:trim_trailing` - if set trailing whitespace is ignored from each line of the output.

  If no option is set a strict equality check is performed.

  Notice that all trimming operations (if needed) will happen both on the captured,
  and expected strings.
  """
  def assert_captured(captured, expected, opts) do
    captured = sanitize(captured, opts)
    expected = sanitize(expected, opts)

    assert captured == expected
  end

  defp sanitize(string, opts) do
    string
    |> then_if(opts[:trim_trailing_newlines] == true, &String.trim_trailing(&1, "\n"))
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> then_if(opts[:trim_whitespace] == true, &String.trim(&1))
      |> then_if(opts[:trim_leading] == true, &String.trim_leading(&1))
      |> then_if(opts[:trim_trailing] == true, &String.trim_trailing(&1))
    end)
  end

  defp then_if(value, true, then_fn), do: then_fn.(value)
  defp then_if(value, false, _then_fn), do: value

  # defp cli_output_to_list(string, opts) do
  #  String.split(string, "\n")
  # end
end
