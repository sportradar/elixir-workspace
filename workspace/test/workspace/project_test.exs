defmodule Workspace.ProjectTest do
  use ExUnit.Case

  alias Workspace.Project
  doctest Workspace.Project

  @sample_workspace_path "test/fixtures/sample_workspace"

  describe "new/2" do
    test "creates a valid project" do
      project_path = Path.join(@sample_workspace_path, "project_a")
      project = Project.new(project_path, @sample_workspace_path)

      assert project.module == ProjectA.MixProject
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
      relative_path = Path.join(@sample_workspace_path, "project_a")
      relative_mix_path = Path.join(relative_path, "mix.exs")

      assert Project.in_project(relative_path, fn module -> module end) == ProjectA.MixProject
      assert Project.in_project(relative_mix_path, fn module -> module end) == ProjectA.MixProject

      assert Project.in_project(Path.expand(relative_path), fn module -> module end) ==
               ProjectA.MixProject

      assert Project.in_project(Path.expand(relative_mix_path), fn module -> module end) ==
               ProjectA.MixProject
    end

    test "raises if invalid project or mix file" do
      error_message = ~r"expected to get a valid path to a `mix.exs` file"

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
    project_path = Path.join(@sample_workspace_path, "project_a")
    project = Project.new(project_path, @sample_workspace_path)

    assert Project.relative_to_workspace(project) == "project_a"
  end
end
