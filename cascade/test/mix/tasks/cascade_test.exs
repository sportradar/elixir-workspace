defmodule Mix.Tasks.CascadeTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @moduletag :tmp_dir

  setup context do
    on_exit(fn ->
      File.rm_rf!(context.tmp_dir)
    end)

    :ok
  end

  test "new template", %{tmp_dir: tmp_dir} do
    in_tmp(tmp_dir, "new_template", fn ->
      capture_io(fn -> Mix.Tasks.Cascade.run(["template", "--", "--name", "foo"]) end)

      assert_file(tmp_dir, "new_template/templates/foo/README.md", fn file ->
        assert file =~ "## About"
        assert file =~ "This is a placeholder"
      end)
    end)
  end

  defp in_tmp(tmp_dir, name, fun) do
    path = Path.join(tmp_dir, name)

    File.rm_rf!(path)
    File.mkdir_p!(path)
    File.cd!(path, fun)

    # clean it afterwards
    File.rm_rf!(path)
  end

  defp assert_file(path, file) do
    path = Path.join(path, file)
    assert File.regular?(path), "expected #{file} to exist"
  end

  defp assert_file(path, file, match) when is_struct(match, Regex),
    do: assert_file(path, file, fn content -> assert content =~ match end)

  defp assert_file(path, file, match) when is_function(match, 1) do
    assert_file(path, file)

    path = Path.join(path, file)
    match.(File.read!(path))
  end
end
