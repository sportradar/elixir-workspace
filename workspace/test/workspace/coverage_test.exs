defmodule Workspace.CoverageTest do
  use ExUnit.Case, async: true

  alias Workspace.Coverage

  test "summarize_line_coverage/1 with no lines" do
    assert Coverage.summarize_line_coverage([]) == {100.0, []}
  end

  describe "beams/2" do
    @tag :tmp_dir
    test "consolidated protocols are loaded from the code server", %{tmp_dir: tmp_dir} do
      compile_path = Path.join(tmp_dir, "ebin")
      consolidation_path = Path.join(tmp_dir, "consolidated")

      for dir <- [compile_path, consolidation_path], do: File.mkdir_p!(dir)

      for file <- ["Elixir.Foo.beam", "Elixir.Enumerable.beam", "foo.app"],
          do: File.touch!(Path.join(compile_path, file))

      File.touch!(Path.join(consolidation_path, "Elixir.Enumerable.beam"))

      assert Enum.sort(Coverage.beams(compile_path, consolidation_path)) ==
               Enum.sort([
                 :code.which(Enumerable),
                 String.to_charlist(Path.join(compile_path, "Elixir.Foo.beam"))
               ])

      # without a consolidation directory all beams are loaded from the compile path
      assert Enum.sort(Coverage.beams(compile_path, Path.join(tmp_dir, "missing"))) ==
               Enum.sort([
                 String.to_charlist(Path.join(compile_path, "Elixir.Enumerable.beam")),
                 String.to_charlist(Path.join(compile_path, "Elixir.Foo.beam"))
               ])
    end
  end

  test "ensure_cover_compiled!/2" do
    assert Coverage.ensure_cover_compiled!([], "ebin") == :ok

    assert_raise Mix.Error,
                 ~s(Failed to cover compile directory "ebin" with reason: :not_main_node),
                 fn -> Coverage.ensure_cover_compiled!({:error, :not_main_node}, "ebin") end
  end
end
