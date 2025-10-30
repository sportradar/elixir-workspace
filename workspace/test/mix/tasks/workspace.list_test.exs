defmodule Mix.Tasks.Workspace.ListTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.List, as: ListTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @tag :tmp_dir
  test "prints the workspace projects with default settings", %{tmp_dir: tmp_dir} do
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
  test "with an empty workspace", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], [], fn ->
      assert capture_io(fn ->
               ListTask.run(["--workspace-path", tmp_dir])
             end) == "No matching projects for the given options\n"
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
  test "with --include option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        # Filter to only package_a, but include package_b and package_c
        expected = """
        Found 3 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
          * :package_b package_b/mix.exs - a dummy project
          * :package_c package_c/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "-p",
                   "package_a",
                   "-i",
                   "package_b",
                   "-i",
                   "package_c"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "with --include but exclude has priority", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        # Filter to package_a and package_b, exclude package_b, but try to include it
        # Exclude should win
        expected = """
        Found 1 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "-p",
                   "package_a,package_b",
                   "-e",
                   "package_b",
                   "-i",
                   "package_b"
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
  test "filtering by --dependency with --recursive", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        # Without --recursive: only package_c and package_f have package_g as direct dependency
        # With --recursive: package_a also transitively depends on package_g (through package_b and package_c->package_f)
        expected = """
        Found 4 workspace projects matching the given options.
          * :package_a package_a/mix.exs :shared, area:core
          * :package_b package_b/mix.exs - a dummy project
          * :package_c package_c/mix.exs
          * :package_f package_f/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--dependency",
                   "package_g",
                   "--recursive"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "filtering by --dependent with --recursive", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        # Without --recursive: package_a depends directly on package_b, package_c, package_d
        # With --recursive: also includes transitive dependencies like package_e, package_f, package_g
        expected = """
        Found 6 workspace projects matching the given options.
          * :package_b package_b/mix.exs - a dummy project
          * :package_c package_c/mix.exs
          * :package_d package_d/mix.exs
          * :package_e package_e/mix.exs
          * :package_f package_f/mix.exs
          * :package_g package_g/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--dependent",
                   "package_a",
                   "--recursive"
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

        capture_io(:stderr, fn ->
          assert capture_io(fn ->
                   ListTask.run([
                     "--workspace-path",
                     tmp_dir,
                     "--json",
                     "--output",
                     output
                   ])
                 end) == expected
        end)

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

        capture_io(:stderr, fn ->
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
        end)

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

        capture_io(:stderr, fn ->
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
        end)

        assert %{"projects" => projects} = File.read!(output) |> Jason.decode!()

        assert length(projects) == 9
      end
    )
  end

  @tag :tmp_dir
  test "prints the workspace projects when base and head are set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_c")
        Workspace.Test.commit_changes(tmp_dir)

        expected = """
        Found 11 workspace projects matching the given options.
          * :package_a ● package_a/mix.exs :shared, area:core
          * :package_b ✔ package_b/mix.exs - a dummy project
          * :package_c ✚ package_c/mix.exs
          * :package_d ✔ package_d/mix.exs
          * :package_e ✔ package_e/mix.exs
          * :package_f ✔ package_f/mix.exs
          * :package_g ✔ package_g/mix.exs
          * :package_h ✔ package_h/mix.exs
          * :package_i ✔ package_i/mix.exs
          * :package_j ✔ package_j/mix.exs
          * :package_k ✔ nested/package_k/mix.exs
        """

        assert capture_io(fn ->
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--show-status",
                   "--base",
                   "HEAD~1",
                   "--head",
                   "HEAD"
                 ])
               end) == expected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "with --format pretty option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
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
                 ListTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--format",
                   "pretty"
                 ])
               end) == expected
      end
    )
  end

  @tag :tmp_dir
  test "with --format json option set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        output =
          capture_io(fn ->
            ListTask.run([
              "--workspace-path",
              tmp_dir,
              "--format",
              "json"
            ])
          end)

        data = Jason.decode!(output)

        assert length(data["projects"]) == 11
        assert Path.type(data["workspace_path"]) == :absolute

        for project <- data["projects"] do
          assert Path.type(project["workspace_path"]) == :absolute
          assert Path.type(project["mix_path"]) == :absolute
          assert Path.type(project["path"]) == :absolute
        end
      end
    )
  end

  @tag :tmp_dir
  test "with --format json and --output option set", %{tmp_dir: tmp_dir} do
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
                   "--format",
                   "json",
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
  test "with --format json and --relative-paths", %{tmp_dir: tmp_dir} do
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
                   "--format",
                   "json",
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
  test "with --format json and filtering options", %{tmp_dir: tmp_dir} do
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
                   "--format",
                   "json",
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
