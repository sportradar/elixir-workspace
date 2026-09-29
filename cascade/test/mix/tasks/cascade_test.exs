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

      assert_file(tmp_dir, "new_template/templates/foo/PLACEHOLDER.md", fn file ->
        assert file =~ "## About"
        assert file =~ "This is a placeholder"
      end)
    end)
  end

  test "new template module is derived from the app name", %{tmp_dir: tmp_dir} do
    in_tmp(tmp_dir, "my-lib", fn ->
      capture_io(fn -> Mix.Tasks.Cascade.run(["template", "--", "--name", "foo"]) end)

      assert_file(tmp_dir, "my-lib/lib/cascade/templates/foo.ex", fn file ->
        assert file =~ "defmodule Cascade.Templates.Foo do"
      end)

      assert_raise Mix.Error, ~r/invalid module name "My-lib.Templates.Bar"/, fn ->
        Mix.Tasks.Cascade.run([
          "template",
          "--",
          "--name",
          "bar",
          "--templates-path",
          "my-lib/templates"
        ])
      end
    end)
  end

  test "new template with an invalid name", %{tmp_dir: tmp_dir} do
    in_tmp(tmp_dir, "invalid_name", fn ->
      for name <- ["../../evil", "Foo", "foo-bar", "1foo", "foo\n"] do
        assert_raise Mix.Error, ~r/invalid template name/, fn ->
          Mix.Tasks.Cascade.run(["template", "--", "--name", name])
        end
      end

      assert File.ls!(tmp_dir) == ["invalid_name"]
      assert File.ls!(Path.join(tmp_dir, "invalid_name")) == []
    end)
  end

  test "with invalid template name" do
    assert_raise Mix.Error,
                 ~r"no template :unknown found",
                 fn ->
                   Mix.Tasks.Cascade.run(["unknown"])
                 end
  end

  test "with multiple templates given" do
    assert_raise Mix.Error,
                 ~r/expected a single template to be given, please use "mix cascade template_name"/,
                 fn ->
                   Mix.Tasks.Cascade.run(["unknown", "unknown"])
                 end
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
