defmodule Workspace.UtilsTest do
  use ExUnit.Case

  alias Workspace.Utils

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
        a
        b
        c
        d

        a --> b
        a --> c
        b --> d
        d --> a
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
        a
        b
        c\
      """

      assert Utils.digraph_to_mermaid(graph) == expected
    end
  end

  describe "format_duration/2" do
    test "raises with negative durations" do
      assert_raise ArgumentError, "duration must be a non negative integer, got: -100", fn ->
        Utils.format_duration(-100)
      end
    end

    test "formats duration" do
      # seconds only
      assert Utils.format_duration(20, :second) == "20.0s"
      assert Utils.format_duration(20_235, :millisecond) == "20.23s"

      # minutes
      assert Utils.format_duration(164, :second) == "2m 44.0s"
      assert Utils.format_duration(164_235, :millisecond) == "2m 44.23s"

      # hours
      assert Utils.format_duration(7432, :second) == "2h 3m 52.0s"
      assert Utils.format_duration(7_164_235, :millisecond) == "1h 59m 24.23s"

      # edge cases
      assert Utils.format_duration(0, :second) == "0.0s"
      assert Utils.format_duration(60, :second) == "1m 0.0s"
      assert Utils.format_duration(3600, :second) == "1h 0.0s"
    end
  end
end
