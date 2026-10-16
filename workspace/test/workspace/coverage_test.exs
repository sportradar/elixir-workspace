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

  describe "quote_only_lines/1" do
    test "returns the lines whose only code is a quote" do
      # mix test compiles without debug info, and the lines are read from it
      debug_info = Code.get_compiler_option(:debug_info)
      Code.put_compiler_option(:debug_info, true)
      on_exit(fn -> Code.put_compiler_option(:debug_info, debug_info) end)

      [{_module, beam}] =
        Code.compile_string("""
        defmodule Workspace.CoverageTest.Quotes do
          defmacro __using__(_opts) do
            quote do
              import Enum
            end
          end

          def assigned do
            ast = quote do: :ok
            ast
          end

          def runtime(x), do: x + 1

          def guarded do
            try do
              quote do: import(Enum)
            after
              quote do: import(Map)
            end
          end

          def nested(x) do
            y =
              (
                z = x + 1
                quote do: unquote(z)
              )

            y
          end
        end
        """)

      if Version.match?(System.version(), ">= 1.20.0") do
        assert Workspace.Coverage.quote_only_lines(beam) == MapSet.new([3, 17, 19, 27])
      else
        assert Workspace.Coverage.quote_only_lines(beam) == MapSet.new()
      end
    end

    test "returns no lines for a beam without abstract code" do
      assert Workspace.Coverage.quote_only_lines(~c"missing.beam") == MapSet.new()
    end
  end

  test "ensure_cover_compiled!/2" do
    assert Coverage.ensure_cover_compiled!([], "ebin") == :ok

    assert_raise Mix.Error,
                 ~s(Failed to cover compile directory "ebin" with reason: :not_main_node),
                 fn -> Coverage.ensure_cover_compiled!({:error, :not_main_node}, "ebin") end
  end
end
