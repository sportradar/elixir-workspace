defmodule Mix.Tasks.Workspace.NewTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @moduletag :tmp_dir

  setup context do
    on_exit(fn ->
      File.rm_rf!(context.tmp_dir)
    end)

    :ok
  end

  describe "valid options" do
    test "new workspace", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, fn ->
        capture_io(fn -> Mix.Tasks.Workspace.New.run(["hello_workspace"]) end)

        assert_file(tmp_dir, "hello_workspace/mix.exs", fn file ->
          assert file =~ "defmodule HelloWorkspace.MixWorkspace do"
          assert file =~ "app: :hello_workspace"
          assert file =~ ~s'version: "0.1.0"'
        end)

        assert_file(tmp_dir, "hello_workspace/README.md", fn file ->
          assert file =~ ~r/# :hello_workspace\n/
          assert file =~ ~r/`:hello_workspace` is a mono-repo managed by `Workspace`/
        end)

        assert_file(tmp_dir, "hello_workspace/.gitignore")
        assert_file(tmp_dir, "hello_workspace/.workspace.exs")
      end)
    end

    test "with module set", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, fn ->
        capture_io(fn -> Mix.Tasks.Workspace.New.run(["hello_workspace", "--module", "Hello"]) end)

        assert_file(tmp_dir, "hello_workspace/mix.exs", ~r/defmodule Hello.MixWorkspace/)
        assert_file(tmp_dir, "hello_workspace/mix.exs", ~r/workspace: \[/)
        assert_file(tmp_dir, "hello_workspace/mix.exs", ~r/type: :workspace/)

        assert_file(tmp_dir, "hello_workspace/README.md", fn file ->
          assert file =~ ~r/# :hello_workspace\n/
          assert file =~ ~r/`:hello_workspace` is a mono-repo managed by `Workspace`/
        end)

        assert_file(tmp_dir, "hello_workspace/.gitignore")
        assert_file(tmp_dir, "hello_workspace/.workspace.exs")
      end)
    end

    test "with app name set", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, fn ->
        capture_io(fn ->
          Mix.Tasks.Workspace.New.run([
            "hello_workspace",
            "--app",
            "hello",
            "--module",
            "HelloWorkspace"
          ])
        end)

        assert_file(tmp_dir, "hello_workspace/mix.exs", fn file ->
          assert file =~ "defmodule HelloWorkspace.MixWorkspace"
          assert file =~ "app: :hello"
        end)

        assert_file(tmp_dir, "hello_workspace/README.md", fn file ->
          assert file =~ ~r/# :hello\n/
          assert file =~ ~r/`:hello` is a mono-repo managed by `Workspace`/
        end)

        assert_file(tmp_dir, "hello_workspace/.gitignore")
        assert_file(tmp_dir, "hello_workspace/.workspace.exs")
      end)
    end
  end

  describe "invalid arguments" do
    test "with invalid path", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "invalid_application_name", fn ->
        assert_raise Mix.Error,
                     ~r"Application name must start with a lowercase ASCII letter, followed by lowercase",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["003"])
                     end
      end)

      in_tmp(tmp_dir, "invalid_application_name_capital", fn ->
        assert_raise Mix.Error,
                     ~r"Application name must start with a lowercase ASCII letter, followed by lowercase",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["invA"])
                     end
      end)

      in_tmp(tmp_dir, "invalid_application_name_non_ascii", fn ->
        assert_raise Mix.Error,
                     ~r"Application name must start with a lowercase ASCII letter, followed by lowercase",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["invάλ"])
                     end
      end)

      in_tmp(tmp_dir, "invalid_application_name_punctuation", fn ->
        assert_raise Mix.Error,
                     ~r"Application name must start with a lowercase ASCII letter, followed by lowercase",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["invalid_!@#"])
                     end
      end)
    end

    test "with invalid app name from --app", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "invalid_application_name", fn ->
        assert_raise Mix.Error,
                     ~r"Application name must start with a lowercase ASCII letter, followed by lowercase",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["path", "--app", "003invalid"])
                     end
      end)
    end

    test "with an invalid module name", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "invalid_module", fn ->
        assert_raise Mix.Error, ~r"Module name must be a valid Elixir alias", fn ->
          Mix.Tasks.Workspace.New.run(["valid", "--module", "not.valid"])
        end
      end)
    end

    test "with an existing module name", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "existing_module", fn ->
        assert_raise Mix.Error,
                     ~r/Module name Mix is already taken, please choose another name/,
                     fn ->
                       Mix.Tasks.Workspace.New.run(["mix"])
                     end
      end)
    end

    test "with an existing module name from the app option", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "invalid_app", fn ->
        assert_raise Mix.Error,
                     ~r/Module name Mix is already taken, please choose another name/,
                     fn ->
                       Mix.Tasks.Workspace.New.run(["valid", "--app", "mix"])
                     end
      end)
    end

    test "with an already taken module name from the module option", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "existing_module", fn ->
        assert_raise Mix.Error, ~r"Module name Mix.Tasks.Workspace.New is already taken", fn ->
          Mix.Tasks.Workspace.New.run(["valid", "--module", "Mix.Tasks.Workspace.New"])
        end
      end)
    end

    test "without a path", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "without_path", fn ->
        assert_raise Mix.Error,
                     "Expected PATH to be given, please use `mix workspace.new PATH`",
                     fn ->
                       Mix.Tasks.Workspace.New.run([])
                     end
      end)
    end

    test "new with existing directory", %{tmp_dir: tmp_dir} do
      in_tmp(tmp_dir, "new_with_existent_directory", fn ->
        File.mkdir_p!("my_app")

        assert_raise Mix.Error,
                     "Directory my_app already exists, please select another directory for your workspace",
                     fn ->
                       Mix.Tasks.Workspace.New.run(["my_app"])
                     end
      end)
    end
  end

  defp in_tmp(tmp_dir, fun) do
    in_tmp(tmp_dir, "", fun)

    # clean it afterwards
    # File.rm_rf!(path)
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
