defmodule Workspace.ProjectTest do
  use ExUnit.Case

  alias Mix.Project
  alias Mix.Project
  alias Workspace.Project
  doctest Workspace.Project

  @sample_workspace_path Workspace.TestUtils.fixture_path(:sample_workspace)

  describe "new/2" do
    test "creates a valid project" do
      project_path = Path.join(@sample_workspace_path, "package_a")
      project = Project.new(project_path, @sample_workspace_path)

      assert project.module == PackageA.MixProject
      assert project.tags == [:shared, {:area, :core}]
    end

    test "evaluates project config functions if needed" do
      project_path = Path.join(@sample_workspace_path, "package_d")
      project = Project.new(project_path, @sample_workspace_path)

      assert project.config[:docs] == [foo: 1]
      assert project.tags == []
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

    test "another valid project" do
      relative_path = Path.join(@sample_workspace_path, "package_a")
      relative_mix_path = Path.join(relative_path, "mix.exs")

      assert Project.in_project(relative_path, fn module -> module end) == PackageA.MixProject
      assert Project.in_project(relative_mix_path, fn module -> module end) == PackageA.MixProject

      assert Project.in_project(Path.expand(relative_path), fn module -> module end) ==
               PackageA.MixProject

      assert Project.in_project(Path.expand(relative_mix_path), fn module -> module end) ==
               PackageA.MixProject
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

  test "relative_to_workspace/1" do
    project_path = Path.join(@sample_workspace_path, "package_a")
    project = Project.new(project_path, @sample_workspace_path)

    assert Project.relative_to_workspace(project) == "package_a"
  end

  test "to_map/1" do
    project_path = Path.join(@sample_workspace_path, "package_a")
    project = Project.new(project_path, @sample_workspace_path)

    assert Project.to_map(project) == %{
             module: "PackageA.MixProject",
             status: "undefined",
             path: Path.join(@sample_workspace_path, "package_a") |> Path.expand(),
             root: nil,
             app: "package_a",
             mix_path:
               Path.join([@sample_workspace_path, "package_a", "mix.exs"]) |> Path.expand(),
             workspace_path: Path.expand(@sample_workspace_path),
             changes: [],
             tags: [":shared", "area:core"]
           }
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
      project = Workspace.TestUtils.project_fixture(app: :foo)

      assert_raise ArgumentError,
                   "Cannot mark :foo as modified without any associated changes",
                   fn ->
                     Workspace.Project.modified(project, [])
                   end
    end

    test "assigns the changes and marks the project modified" do
      project =
        Workspace.TestUtils.project_fixture(app: :foo)
        |> Project.modified(["README.md"])

      assert project.status == :modified
      assert project.changes == ["README.md"]
    end
  end
end
