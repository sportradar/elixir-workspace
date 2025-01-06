defmodule Mix.Tasks.Workspace.ListTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.List, as: ListTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @tag :tmp_dir
  test "prints the tree of the workspace", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      Found 11 workspace projects matching the given options.
        * :package_a package_a/mix.exs :shared, area:core
        * :package_b package_b/mix.exs - a dummy project
        * :package_c package_c/mix.exs
        * :package_d package_d/mix.exs
        * :package_e package_e/mix.exs
        * :package_f package_f/mix.exs
        * :package_g package_g/mix.exs
        * :package_h package_h/mix.exs
        * :package_i package_i/mix.exs
        * :package_j package_j/mix.exs
        * :package_k nested/package_k/mix.exs
      """

      assert capture_io(fn ->
               ListTask.run(["--workspace-path", tmp_dir])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "with --show-status flag", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_d")
        Workspace.Test.modify_project(tmp_dir, "package_e")

        expected = """
        Found 11 workspace projects matching the given options.
          * :package_a ● package_a/mix.exs :shared, area:core
          * :package_b ✔ package_b/mix.exs - a dummy project
          * :package_c ● package_c/mix.exs
          * :package_d ✚ package_d/mix.exs
          * :package_e ✚ package_e/mix.exs
          * :package_f ✔ package_f/mix.exs
          * :package_g ✔ package_g/mix.exs
          * :package_h ● package_h/mix.exs
          * :package_i ✔ package_i/mix.exs
          * :package_j ✔ package_j/mix.exs
          * :package_k ✔ nested/package_k/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run(["--workspace-path", tmp_dir, "--show-status"])
               end) == expected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "with --project option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 2 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
          * :package_b package_b/mix.exs - a dummy project
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "-p",
                   "package_a",
                   "-p",
                   "package_b"
                 ])
               end) == expected

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "-p",
                   "invalid"
                 ])
               end) =~ "No matching projects for the given options"
      end
    )
  end

  @tag :tmp_dir
  test "with --exclude option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 1 workspace projects matching the given options.
          * :package_b package_b/mix.exs - a dummy project
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "-p",
                   "package_a",
                   "-p",
                   "package_b",
                   "-e",
                   "package_a"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by --maintainer", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 1 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--maintainer",
                   "jack"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by --dependency", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 2 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
          * :package_h package_h/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--dependency",
                   "package_d"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by --dependent", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 3 workspace projects matching the given options.
          * :package_b package_b/mix.exs - a dummy project
          * :package_c package_c/mix.exs
          * :package_d package_d/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--dependent",
                   "package_a"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by both --dependency and --dependent", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 1 workspace projects matching the given options.
          * :package_c package_c/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--dependency",
                   "package_e",
                   "--dependent",
                   "package_a"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by --path", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        Found 2 workspace projects matching the given options.
          * :package_c package_c/mix.exs
          * :package_d package_d/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--path",
                   "package_c",
                   "--path",
                   "package_d"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "with --json option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_d")
        Workspace.Test.modify_project(tmp_dir, "package_e")

        output = Path.join(tmp_dir, "workspace.json")

        expected = """
        ==> generated #{output}
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--json",
                   "--output",
                   output
                 ])
               end) == expected

        data = File.read!(output) |> Jason.decode!()

        assert length(data["projects"]) == 11
        assert Path.type(data["workspace_path"]) == :absolute

        for project <- data["projects"] do
          assert Path.type(project["workspace_path"]) == :absolute
          assert Path.type(project["mix_path"]) == :absolute
          assert Path.type(project["path"]) == :absolute
        end
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "with --json and --relative-paths", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        output = Path.join(tmp_dir, "workspace.json")

        expected = """
        ==> generated #{output}
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--json",
                   "--output",
                   output,
                   "--relative-paths"
                 ])
               end) == expected

        data = File.read!(output) |> Jason.decode!()

        assert data["workspace_path"] == "."
        assert length(data["projects"]) == 11

        for project <- data["projects"] do
          assert project["workspace_path"] == "."
          assert Path.type(project["mix_path"]) == :relative
          assert Path.type(project["path"]) == :relative
        end
      end
    )
  end

  @tag :tmp_dir
  test "with --json option set and --exclude", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        output = Path.join(tmp_dir, "workspace.json")

        expected = """
        ==> generated #{output}
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--json",
                   "--output",
                   output,
                   "-e",
                   "package_a",
                   "-e",
                   "package_b"
                 ])
               end) == expected

        assert %{"projects" => projects} = File.read!(output) |> Jason.decode!()

        assert length(projects) == 9
      end
    )
  end
end
