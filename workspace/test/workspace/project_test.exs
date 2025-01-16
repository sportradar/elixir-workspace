defmodule Workspace.ProjectTest do
  use ExUnit.Case

  alias Workspace.Project
  doctest Workspace.Project

  describe "new/2" do
    @tag :tmp_dir
    test "creates a valid project", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [{:package_a, "package_a", [workspace: [tags: [:shared, {:area, :core}]]]}],
        fn ->
          project_path = Path.join(tmp_dir, "package_a")
          project = Project.new(project_path, tmp_dir)

          assert project.module == PackageA.MixProject
          assert project.tags == [:shared, {:area, :core}]
        end
      )
    end

    @tag :tmp_dir
    test "evaluates project config functions if needed", %{tmp_dir: tmp_dir} do
      Workspace.Test.in_fixture(tmp_dir, fn ->
        mix_content = """
        defmodule AnonymousFunction.MixProject do
          use Mix.Project

          def project do
            [
              app: :anonymous_function,
              version: "0.1.0",
              elixir: "~> 1.14",
              start_permanent: Mix.env() == :prod,
              deps: [],
              docs: &docs/0
            ]
          end

          def application, do: []

          defp docs, do: [foo: 1]
        end
        """

        Workspace.Test.create_mix_project(
          tmp_dir,
          :anonymous_function,
          "anonymous_function",
          mix_content
        )

        project_path = Path.join(tmp_dir, "anonymous_function")
        project = Project.new(project_path, tmp_dir)

        assert project.config[:docs] == [foo: 1]
        assert project.tags == []
      end)
    end

    # dummy test just for test coverage
    test "create struct directly" do
      project = %Project{
        app: :app,
        module: Project.MixProject,
        config: [],
        mix_path: "mix.exs",
        path: ".",
        workspace_path: File.cwd!()
      }

      assert project.app == :app
    end

    test "raises in case of invalid global configuration" do
      project_path = "test/fixtures/invalid_project"

      message = "invalid value for :tags option: expected list, got: 1"

      assert_raise NimbleOptions.ValidationError, message, fn ->
        Project.new(project_path, "test/fixtures")
      end
    end
  end

  describe "in_project/2" do
    test "current project" do
      assert Project.in_project(".", fn module -> module end) == Mix.Project.get!()
      assert Project.in_project("mix.exs", fn module -> module end) == Mix.Project.get!()
      assert Project.in_project(File.cwd!(), fn module -> module end) == Mix.Project.get!()

      assert Project.in_project(Path.join(File.cwd!(), "mix.exs"), fn module -> module end) ==
               Mix.Project.get!()
    end

    @tag :tmp_dir
    test "handles both relative and absolute paths", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], [{:foo, "foo", []}], fn ->
        relative_path = Path.join(tmp_dir, "foo")
        relative_mix_path = Path.join(relative_path, "mix.exs")

        assert Project.in_project(relative_path, fn module -> module end) == Foo.MixProject

        assert Project.in_project(relative_mix_path, fn module -> module end) ==
                 Foo.MixProject

        assert Project.in_project(Path.expand(relative_path), fn module -> module end) ==
                 Foo.MixProject

        assert Project.in_project(Path.expand(relative_mix_path), fn module -> module end) ==
                 Foo.MixProject
      end)
    end

    test "raises if invalid project or mix file" do
      error_message = ~r"dummy/mix.exs does not exist"

      assert_raise ArgumentError, error_message, fn ->
        Project.in_project("dummy", fn _ -> nil end)
      end

      assert_raise ArgumentError, error_message, fn ->
        Project.in_project("dummy/mix.exs", fn _ -> nil end)
      end
    end
  end

  describe "ensure_mix_file!/1" do
    test "valid mix files" do
      assert Project.ensure_mix_file!("mix.exs") == :ok
      assert Project.ensure_mix_file!(Path.join(File.cwd!(), "mix.exs")) == :ok
    end

    test "invalid mix files" do
      assert_raise ArgumentError, fn -> Project.ensure_mix_file!("mix.ex") end

      assert_raise ArgumentError, fn ->
        Project.ensure_mix_file!("dummy/mix.exs")
      end
    end
  end

  @tag :tmp_dir
  test "relative_to_workspace/1", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], [{:foo, "foo", []}], fn ->
      project_path = Path.join(tmp_dir, "foo")
      project = Project.new(project_path, tmp_dir)

      assert Project.relative_to_workspace(project) == "foo"
    end)
  end

  @tag :tmp_dir
  test "to_map/1", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [{:foo_bar, "packages/foo_bar", [workspace: [tags: [:foo, {:area, :bar}]]]}],
      fn ->
        project_path = Path.join(tmp_dir, "packages/foo_bar")
        project = Project.new(project_path, tmp_dir)

        assert Project.to_map(project) == %{
                 module: "FooBar.MixProject",
                 status: "undefined",
                 path: Path.join(tmp_dir, "packages/foo_bar") |> Path.expand(),
                 root: nil,
                 app: "foo_bar",
                 mix_path: Path.join([tmp_dir, "packages/foo_bar", "mix.exs"]) |> Path.expand(),
                 workspace_path: Path.expand(tmp_dir),
                 changes: [],
                 tags: [":foo", "area:bar"]
               }
      end
    )
  end

  describe "tags tests" do
    test "project with no tags" do
      project = Workspace.TestUtils.project_fixture(app: :foo, workspace: [tags: []])

      # has_tag?/2
      assert Project.has_tag?(project, :*)
      refute Project.has_tag?(project, :foo)

      # has_scoped_tag?/2
      refute Project.has_scoped_tag?(project, :foo)

      # scoped_tags/2
      assert Project.scoped_tags(project, :foo) == []

      # has_any_tag?/2
      assert Project.has_any_tag?(project, [:foo, :bar, :*])
      refute Project.has_any_tag?(project, [:foo, :bar, :baz])
    end

    test "with multiple tags" do
      project =
        Workspace.TestUtils.project_fixture(
          app: :foo,
          workspace: [tags: [:foo, :bar, {:scope, :shared}, {:scope, :admin}, {:team, :ui}]]
        )

      # has_tag?/2
      assert Project.has_tag?(project, :*)
      assert Project.has_tag?(project, :foo)

      # has_scoped_tag?/2
      refute Project.has_scoped_tag?(project, :foo)
      assert Project.has_scoped_tag?(project, :scope)
      assert Project.has_scoped_tag?(project, :team)

      # scoped_tags/2
      assert Project.scoped_tags(project, :foo) == []
      assert Project.scoped_tags(project, :scope) == [{:scope, :shared}, {:scope, :admin}]
      assert Project.scoped_tags(project, :team) == [{:team, :ui}]

      # has_any_tag?/2
      assert Project.has_any_tag?(project, [:foo, :bar, :*])
      assert Project.has_any_tag?(project, [:foo, :bar, :baz])
      refute Project.has_any_tag?(project, [:baz, :goo])
      refute Project.has_any_tag?(project, [{:scope, :foo}, {:scope, :bar}])
      assert Project.has_any_tag?(project, [{:scope, :foo}, {:scope, :bar}, {:scope, :admin}])
    end

    test "format_tag/1" do
      assert Project.format_tag(:foo) == ":foo"
      assert Project.format_tag({:scope, :foo}) == "scope:foo"
    end
  end

  describe "modified/2" do
    test "raises if no changes" do
      project = Workspace.Test.project_fixture(:foo, "foo", [])

      assert_raise ArgumentError,
                   "Cannot mark :foo as modified without any associated changes",
                   fn ->
                     Workspace.Project.modified(project, [])
                   end
    end

    test "assigns the changes and marks the project modified" do
      project =
        Workspace.Test.project_fixture(:foo, "foo", [])
        |> Project.modified(["README.md"])

      assert project.status == :modified
      assert project.changes == ["README.md"]
    end
  end
end
