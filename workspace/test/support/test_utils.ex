defmodule TestUtils do
  @moduledoc false

  require ExUnit.Assertions
  import ExUnit.Assertions
  import ExUnit.CaptureIO

  ## Working with fixtures

  def fixture_path, do: Path.expand("../fixtures", __DIR__)

  def fixture_path(fixture), do: Path.join(fixture_path(), fixture)

  # tmp folders are created by default in a workspace_test_fixtures folder
  # at the same level as the git repo
  #
  # since we work with git commands and we want to test both git and non
  # git repos we cannot use the current folder
  def tmp_path do
    {root_git, 0} = System.cmd("git", ~w[rev-parse --show-toplevel], stderr_to_stdout: true)

    Path.join([root_git, "../workspace_test_fixtures"])
    |> Path.expand()
  end

  def tmp_path(path), do: Path.join(tmp_path(), path)

  def delete_tmp_dirs, do: File.rm_rf!(tmp_path())

  defmacro test_fixture_path do
    tmp_path = test_fixture_path(__CALLER__) |> tmp_path()

    quote do
      unquote(tmp_path)
    end
  end

  def test_fixture_path(caller) do
    module = inspect(caller.module)
    function = Atom.to_string(elem(caller.function, 0))

    Path.join(module, function) |> String.replace(":", "_")
  end

  # Runs the block code in a temporary folder where the contents of
  # the given fixture will be copied.
  #
  # This is borrowed from the Mix test helpers
  defmacro in_fixture(fixture, block) do
    tmp_path = test_fixture_path(__CALLER__)

    quote do
      unquote(__MODULE__)._in_fixture(unquote(fixture), unquote(tmp_path), unquote(block))
    end
  end

  # similar to in_fixture/2 but specify a default name for it
  defmacro in_fixture(fixture, dirname, block) do
    quote do
      unquote(__MODULE__)._in_fixture(unquote(fixture), unquote(dirname), unquote(block))
    end
  end

  def _in_fixture(which, dest, function) do
    path = create_fixture(which, dest)

    try do
      File.cd!(path, function)
    after
      :ok
    end

    path
  end

  # Copies the given fixture to the given dirname under the tmp folder
  # Useful in case you need to use the same fixture in multiple
  # tests.
  #
  # You should initialize such fixtures in test_helper.exs
  def create_fixture(fixture, dirname) do
    tmp_path = tmp_path(dirname)

    src = fixture_path(fixture)

    File.rm_rf!(tmp_path)
    File.mkdir_p!(tmp_path)
    File.cp_r!(src, tmp_path)

    tmp_path
  end

  def make_fixture_unique(fixture_path, suffix) do
    # replace the content of all ex and exs files
    Path.join(fixture_path, "**/*.{exs,ex}")
    |> Path.wildcard()
    |> Enum.each(&add_suffix_to_module(&1, suffix))

    # rename all package folders
    Path.join(fixture_path, "**/{package,project}_*")
    |> Path.wildcard()
    |> Enum.filter(&File.dir?/1)
    |> Enum.each(fn path ->
      new_folder_name =
        path
        |> Path.basename()
        |> String.replace("package_", "package_#{suffix}")
        |> String.replace("project_", "project_#{suffix}")

      new_path =
        path
        |> Path.dirname()
        |> Path.join(new_folder_name)

      File.rename(path, new_path)
    end)
  end

  defp add_suffix_to_module(path, suffix) do
    content = File.read!(path)

    content =
      ["MixWorkspace", "_workspace", "Package", "package_"]
      |> Enum.reduce(content, fn pattern, content ->
        String.replace(content, pattern, "#{pattern}#{suffix}")
      end)

    File.write(path, content)
  end

  def purge(modules) do
    Enum.each(modules, fn m ->
      IO.puts("purging #{m}")
      :code.purge(m)
      :code.delete(m)
    end)
  end

  # creates a simple project fixture in memory
  def project_fixture(config, opts \\ []) do
    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")
    path = Keyword.get(opts, :path, "packages")

    app = Keyword.fetch!(config, :app)
    project_path = Path.join([workspace_path, path, Atom.to_string(app)])

    %Workspace.Project{
      app: app,
      module: project_module(app),
      config: config,
      mix_path: Path.join(project_path, "mix.exs"),
      path: project_path,
      workspace_path: workspace_path
    }
  end

  # creates a workspace fixture
  def workspace_fixture(projects, opts \\ []) do
    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")

    %Workspace.State{
      config: [],
      mix_path: Path.join(workspace_path, "mix.exs"),
      workspace_path: workspace_path,
      cwd: File.cwd!()
    }
    |> Workspace.State.set_projects(projects)
  end

  defp project_module(app) do
    (Macro.camelize(Atom.to_string(app)) <> ".MixProject")
    |> String.to_atom()
  end

  # Get a single project by name
  def project_by_name(projects, name) do
    case Enum.filter(projects, fn project -> project.app == name end) do
      [project] -> project
      _ -> raise ArgumentError, "no project with the given name #{name}"
    end
  end

  # formats the ansidata message to a string
  # TODO: maybe move to a public function
  def format_ansi(message) do
    IO.ANSI.format(message) |> :erlang.iolist_to_binary()
  end

  # initializes the current folder as a git project
  # NOTICE that this must be used only within a fixture
  # if no path is provided the current working directory is used
  def init_git_project, do: init_git_project(File.cwd!())

  def init_git_project(path) do
    File.cd!(path, fn ->
      System.cmd("git", ~w[init])
      System.cmd("git", ~w[add .])
      System.cmd("git", ~w[commit -m "commit"])
      System.cmd("git", ~w[symbolic-ref HEAD refs/heads/main])
    end)
  end

  def cmd_in_path(path, cmd, args) do
    File.cd!(path, fn -> System.cmd(cmd, args) end)
  end

  # compares the captured output with the expected one
  #
  # notice that empty lines are removed from the captures
  # and it is transformed to a list of lines
  #
  # Options
  #
  # if partial is set to `true` we pattern match only the given output lines
  def assert_cli_output_match(captured, expected, opts \\ []) do
    captured =
      captured
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(fn line -> line != "" end)

    partial = Keyword.get(opts, :partial, false)

    case partial do
      false ->
        # if the lengths are not the same print the full lists for
        # debugging
        if length(expected) != length(captured) do
          assert expected == captured
        end

        mismatches =
          Enum.zip(captured, expected)
          |> Enum.map(fn {captured_line, expected_line} ->
            captured_line =~ expected_line
          end)
          |> Enum.filter(fn status -> status == false end)

        case mismatches do
          [] -> assert true
          _errors -> assert expected == captured
        end

      true ->
        captured = Enum.join(captured, "\n")

        for line <- expected do
          assert captured =~ line
        end
    end
  end

  def assert_raise_and_capture_io(exception, message, fun) do
    capture_io(fn -> assert_raise exception, message, fn -> fun.() end end)
  end
end
