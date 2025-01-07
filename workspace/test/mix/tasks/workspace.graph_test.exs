defmodule Mix.Tasks.Workspace.GraphTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Graph, as: GraphTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @tag :tmp_dir
  test "prints the tree of the workspace", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_a
      ├── :package_b
      │   └── :package_g
      ├── :package_c
      │   ├── :package_e
      │   └── :package_f
      │       └── :package_g
      └── :package_d
      :package_h
      └── :package_d
      :package_i
      └── :package_j
      :package_k
      """

      assert capture_io(fn ->
               GraphTask.run(["--workspace-path", tmp_dir])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "with focus set and default proximity", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_c
      └── :package_f
          └── :package_g
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--focus",
                 "package_f"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "with focus set and custom proximity", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_a
      └── :package_c
          └── :package_f
              └── :package_g
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--focus",
                 "package_f",
                 "--proximity",
                 "2"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "with plain output format", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_a
      |-- :package_b
      |   `-- :package_g
      |-- :package_c
      |   |-- :package_e
      |   `-- :package_f
      |       `-- :package_g
      `-- :package_d
      :package_h
      `-- :package_d
      :package_i
      `-- :package_j
      :package_k
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--format",
                 "plain"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "prints the tree with project statuses", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_d")
        Workspace.Test.modify_project(tmp_dir, "package_e")

        expected = """
        :package_a ●
        ├── :package_b ✔
        │   └── :package_g ✔
        ├── :package_c ●
        │   ├── :package_e ✚
        │   └── :package_f ✔
        │       └── :package_g ✔
        └── :package_d ✚
        :package_h ●
        └── :package_d ✚
        :package_i ✔
        └── :package_j ✔
        :package_k ✔
        """

        assert capture_io(fn ->
                 GraphTask.run(["--workspace-path", tmp_dir, "--show-status"])
               end) == expected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "with statuses and tags enabled", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_d")
        Workspace.Test.modify_project(tmp_dir, "package_e")

        expected = """
        :package_a ● :shared, area:core
        ├── :package_b ✔
        │   └── :package_g ✔
        ├── :package_c ●
        │   ├── :package_e ✚
        │   └── :package_f ✔
        │       └── :package_g ✔
        └── :package_d ✚
        :package_h ●
        └── :package_d ✚
        :package_i ✔
        └── :package_j ✔
        :package_k ✔
        """

        assert capture_io(fn ->
                 GraphTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--show-status",
                   "--show-tags"
                 ])
               end) == expected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "prints the tree with project statuses when base and head are set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_c")
        Workspace.Test.commit_changes(tmp_dir)

        expected = """
        :package_a ●
        ├── :package_b ✔
        │   └── :package_g ✔
        ├── :package_c ✚
        │   ├── :package_e ✔
        │   └── :package_f ✔
        │       └── :package_g ✔
        └── :package_d ✔
        :package_h ✔
        └── :package_d ✔
        :package_i ✔
        └── :package_j ✔
        :package_k ✔
        """

        assert capture_io(fn ->
                 GraphTask.run([
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
  test "prints the tree with external dependencies", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = """
        :package_a
        ├── :ex_doc (external)
        ├── :package_b
        │   ├── :foo (external)
        │   └── :package_g
        ├── :package_c
        │   ├── :package_e
        │   └── :package_f
        │       └── :package_g
        └── :package_d
        :package_h
        └── :package_d
        :package_i
        └── :package_j
        :package_k
        """

        assert capture_io(fn ->
                 GraphTask.run(["--workspace-path", tmp_dir, "--external"])
               end) == expected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "with external and focus", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_a
      └── :package_b
          ├── :foo (external)
          └── :package_g
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--external",
                 "--focus",
                 "package_b"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "does not print excluded packages", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      :package_a
      ├── :package_c
      │   └── :package_e
      └── :package_d
      :package_g
      :package_h
      └── :package_d
      :package_i
      └── :package_j
      :package_k
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--exclude",
                 "package_b",
                 "--exclude",
                 "package_f"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "with dot output set", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
      expected = """
      digraph G {
        package_a -> package_c;
        package_a -> package_d;
        package_c -> package_e;
        package_h -> package_d;
        package_i -> package_j;
      }
      """

      assert capture_io(fn ->
               GraphTask.run([
                 "--workspace-path",
                 tmp_dir,
                 "--exclude",
                 "package_b",
                 "--exclude",
                 "package_f",
                 "--format",
                 "dot"
               ])
             end) == expected
    end)
  end

  @tag :tmp_dir
  test "mermaid output format", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        Workspace.Test.modify_project(tmp_dir, "package_d")
        Workspace.Test.modify_project(tmp_dir, "package_e")

        expected = """
        flowchart TD
          package_a
          package_b
          package_c
          package_d
          package_e
          package_f
          package_g
          package_h
          package_i
          package_j
          package_k

          package_a --> package_b
          package_a --> package_c
          package_a --> package_d
          package_b --> package_g
          package_c --> package_e
          package_c --> package_f
          package_f --> package_g
          package_h --> package_d
          package_i --> package_j

          classDef external fill:#999,color:#ee0;
        """

        assert capture_io(fn ->
                 GraphTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--format",
                   "mermaid"
                 ])
               end) == expected

        # with show status flag
        expected =
          expected <>
            """

              class package_a affected;
              class package_c affected;
              class package_d modified;
              class package_e modified;
              class package_h affected;

              classDef affected fill:#FA6,color:#FFF;
              classDef modified fill:#F33,color:#FFF;
            """

        assert capture_io(fn ->
                 GraphTask.run([
                   "--workspace-path",
                   tmp_dir,
                   "--format",
                   "mermaid",
                   "--show-status"
                 ])
               end) == expected

        # with external deps flag
        captured =
          capture_io(fn ->
            GraphTask.run([
              "--workspace-path",
              tmp_dir,
              "--format",
              "mermaid",
              "--external"
            ])
          end)

        assert captured =~ "foo"
        assert captured =~ "package_b --> foo"
      end,
      git: true
    )
  end
end
