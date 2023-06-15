defmodule Workspace.UtilsTest do
  use ExUnit.Case

  alias Workspace.Utils

  describe "relative_path_to/2" do
    test "with absolute paths" do
      assert Utils.relative_path_to("/usr/local/foo", "/usr/local") == "foo"
      assert Utils.relative_path_to("/usr/local/foo", "/") == "usr/local/foo"
      assert Utils.relative_path_to("/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Utils.relative_path_to("/usr/local/foo", "/usr/local/foo") == "."
      assert Utils.relative_path_to("/usr/local/foo/", "/usr/local/foo") == "."
      assert Utils.relative_path_to("/usr/local/foo", "/usr/local/foo/") == "."

      assert Utils.relative_path_to("/etc", "/usr/local/foo") == "../../../etc"
      assert Utils.relative_path_to(~c"/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Utils.relative_path_to("/usr/local", "/usr/local/foo") == ".."
      assert Utils.relative_path_to("/usr/local/..", "/usr/local") == ".."

      assert Utils.relative_path_to("/usr/../etc/foo/../../bar", "/log/foo/../../usr/") ==
               "../bar"
    end

    test "with relative paths" do
      assert Utils.relative_path_to("usr/local/foo", "usr/local") == "foo"
      assert Utils.relative_path_to("usr/local/foo", "etc") == "../usr/local/foo"

      assert Utils.relative_path_to("usr/local/foo", "usr/local") == "foo"
      assert Utils.relative_path_to(["usr", ?/, 'local/foo'], 'usr/local') == "foo"

      # on cwd
      assert Utils.relative_path_to("foo", File.cwd!()) == "foo"
      assert Utils.relative_path_to("./foo", File.cwd!()) == "foo"
      assert Utils.relative_path_to("./foo/.", File.cwd!()) == "foo"
      assert Utils.relative_path_to("./foo/./bar/.", File.cwd!()) == "foo/bar"
      assert Utils.relative_path_to("../foo/./bar/.", File.cwd!()) == "../foo/bar"
      assert Utils.relative_path_to("../foo/./bar/..", File.cwd!()) == "../foo"
      assert Utils.relative_path_to("../foo/../bar/..", File.cwd!()) == ".."
      assert Utils.relative_path_to("./foo/../bar/..", File.cwd!()) == "."

      # both relative
      assert Utils.relative_path_to("usr/local/foo", "usr/local") == "foo"
      assert Utils.relative_path_to("usr/local/foo", "etc") == "../usr/local/foo"
      assert Utils.relative_path_to(~c"usr/local/foo", "etc") == "../usr/local/foo"
    end
  end

  describe "digraph_to_mermaid/1" do
    test "graph with edges" do
      graph = :digraph.new()

      :digraph.add_vertex(graph, :a)
      :digraph.add_vertex(graph, :b)
      :digraph.add_vertex(graph, :c)
      :digraph.add_vertex(graph, :d)

      :digraph.add_edge(graph, :a, :b)
      :digraph.add_edge(graph, :a, :c)
      :digraph.add_edge(graph, :b, :d)
      :digraph.add_edge(graph, :d, :a)
      :digraph.add_edge(graph, :d, :c)

      expected = """
      flowchart TD
        d
        c
        b
        a

        b --> d
        d --> a
        a --> c
        a --> b
        d --> c\
      """

      assert Utils.digraph_to_mermaid(graph) == expected
    end

    test "without edges" do
      graph = :digraph.new()

      :digraph.add_vertex(graph, :a)
      :digraph.add_vertex(graph, :b)
      :digraph.add_vertex(graph, :c)

      expected = """
      flowchart TD
        c
        b
        a\
      """

      assert Utils.digraph_to_mermaid(graph) == expected
    end
  end
end
