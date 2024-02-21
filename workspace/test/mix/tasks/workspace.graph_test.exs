defmodule Mix.Tasks.Workspace.GraphTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Graph, as: GraphTask

  @sample_workspace_default_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_default"
                                 )
  @sample_workspace_changed_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_changed"
                                 )
  @sample_workspace_committed_path Path.join(
                                     Workspace.TestUtils.tmp_path(),
                                     "sample_workspace_committed"
                                   )

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "prints the tree of the workspace" do
    expected = """
    :package_default_a
    ├── :package_default_b
    │   └── :package_default_g
    ├── :package_default_c
    │   ├── :package_default_e
    │   └── :package_default_f
    │       └── :package_default_g
    └── :package_default_d
    :package_default_h
    └── :package_default_d
    :package_default_i
    └── :package_default_j
    :package_default_k
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_default_path])
           end) == expected
  end

  test "with plain output format" do
    expected = """
    :package_default_a
    |-- :package_default_b
    |   `-- :package_default_g
    |-- :package_default_c
    |   |-- :package_default_e
    |   `-- :package_default_f
    |       `-- :package_default_g
    `-- :package_default_d
    :package_default_h
    `-- :package_default_d
    :package_default_i
    `-- :package_default_j
    :package_default_k
    """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_default_path,
               "--format",
               "plain"
             ])
           end) == expected
  end

  test "prints the tree with project statuses" do
    expected = """
    :package_changed_a ●
    ├── :package_changed_b ✔
    │   └── :package_changed_g ✔
    ├── :package_changed_c ●
    │   ├── :package_changed_e ✚
    │   └── :package_changed_f ✔
    │       └── :package_changed_g ✔
    └── :package_changed_d ✚
    :package_changed_h ●
    └── :package_changed_d ✚
    :package_changed_i ✔
    └── :package_changed_j ✔
    :package_changed_k ✔
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_changed_path, "--show-status"])
           end) == expected
  end

  test "with statuses and tags enabled" do
    expected = """
    :package_changed_a ● :shared, area:core
    ├── :package_changed_b ✔
    │   └── :package_changed_g ✔
    ├── :package_changed_c ●
    │   ├── :package_changed_e ✚
    │   └── :package_changed_f ✔
    │       └── :package_changed_g ✔
    └── :package_changed_d ✚
    :package_changed_h ●
    └── :package_changed_d ✚
    :package_changed_i ✔
    └── :package_changed_j ✔
    :package_changed_k ✔
    """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_changed_path,
               "--show-status",
               "--show-tags"
             ])
           end) == expected
  end

  test "prints the tree with project statuses when base and head are set" do
    expected = """
    :package_committed_a ●
    ├── :package_committed_b ✔
    │   └── :package_committed_g ✔
    ├── :package_committed_c ✚
    │   ├── :package_committed_e ✔
    │   └── :package_committed_f ✔
    │       └── :package_committed_g ✔
    └── :package_committed_d ✔
    :package_committed_h ✔
    └── :package_committed_d ✔
    :package_committed_i ✔
    └── :package_committed_j ✔
    :package_committed_k ✔
    """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_committed_path,
               "--show-status",
               "--base",
               "HEAD~1",
               "--head",
               "HEAD"
             ])
           end) == expected
  end

  test "prints the tree with external dependencies" do
    expected = """
    :package_changed_a
    ├── :ex_doc (external)
    ├── :package_changed_b
    │   ├── :foo (external)
    │   └── :package_changed_g
    ├── :package_changed_c
    │   ├── :package_changed_e
    │   └── :package_changed_f
    │       └── :package_changed_g
    └── :package_changed_d
    :package_changed_h
    └── :package_changed_d
    :package_changed_i
    └── :package_changed_j
    :package_changed_k
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_changed_path, "--external"])
           end) == expected
  end

  test "does not print excluded packages" do
    expected = """
    :package_changed_a
    ├── :package_changed_c
    │   └── :package_changed_e
    └── :package_changed_d
    :package_changed_g
    :package_changed_h
    └── :package_changed_d
    :package_changed_i
    └── :package_changed_j
    :package_changed_k
    """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_changed_path,
               "--exclude",
               "package_changed_b",
               "--exclude",
               "package_changed_f"
             ])
           end) == expected
  end

  test "mermaid output format" do
    expected = """
    flowchart TD
      package_changed_a
      package_changed_b
      package_changed_c
      package_changed_d
      package_changed_e
      package_changed_f
      package_changed_g
      package_changed_h
      package_changed_i
      package_changed_j
      package_changed_k

      package_changed_a --> package_changed_b
      package_changed_a --> package_changed_c
      package_changed_a --> package_changed_d
      package_changed_b --> package_changed_g
      package_changed_c --> package_changed_e
      package_changed_c --> package_changed_f
      package_changed_f --> package_changed_g
      package_changed_h --> package_changed_d
      package_changed_i --> package_changed_j

      classDef external fill:#999,color:#ee0;
    """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_changed_path,
               "--format",
               "mermaid"
             ])
           end) == expected

    # with show status flag
    expected =
      expected <>
        """

          class package_changed_a affected;
          class package_changed_c affected;
          class package_changed_d modified;
          class package_changed_e modified;
          class package_changed_h affected;

          classDef affected fill:#FA6,color:#FFF;
          classDef modified fill:#F33,color:#FFF;
        """

    assert capture_io(fn ->
             GraphTask.run([
               "--workspace-path",
               @sample_workspace_changed_path,
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
          @sample_workspace_changed_path,
          "--format",
          "mermaid",
          "--external"
        ])
      end)

    assert captured =~ "foo"
    assert captured =~ "package_changed_b --> foo"
  end
end
