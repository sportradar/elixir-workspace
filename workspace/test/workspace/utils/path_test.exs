defmodule Workspace.Utils.Path.PathTest do
  use ExUnit.Case
  doctest Workspace.Utils.Path

  alias Workspace.Utils

  describe "parent_dir?" do
    test "with absolute dirs" do
      assert Utils.Path.parent_dir?("/usr/local/workspace", "/usr/local/workspace/foo")
      refute Utils.Path.parent_dir?("/usr/local/workspace", "/usr/local/workspace_foo")
      refute Utils.Path.parent_dir?("/usr/local/workspace/foo", "/usr/local/workspace")
    end

    test "with relative dirs" do
      assert Utils.Path.parent_dir?("../local", "../local/foo.ex")
      assert Utils.Path.parent_dir?(".././local", "../local/foo.ex")
      assert Utils.Path.parent_dir?(".", Path.join(File.cwd!(), "foo.ex"))
      refute Utils.Path.parent_dir?("../workspace", "/usr/local/workspace_foo")
    end
  end

  describe "glob_match?" do
    test "exact paths and directories" do
      assert Utils.Path.glob_match?("/ws/shared/config.ex", "/ws/shared/config.ex")
      refute Utils.Path.glob_match?("/ws/shared/config.ex", "/ws/shared/config.exs")

      assert Utils.Path.glob_match?("/ws/shared", "/ws/shared/nested/config.ex")
      assert Utils.Path.glob_match?("/ws/shared/", "/ws/shared/config.ex")
      refute Utils.Path.glob_match?("/ws/shared", "/ws/shared2/config.ex")
    end

    test "single star does not cross directories" do
      assert Utils.Path.glob_match?("/ws/shared/*.ex", "/ws/shared/config.ex")
      refute Utils.Path.glob_match?("/ws/shared/*.ex", "/ws/shared/config.txt")
      refute Utils.Path.glob_match?("/ws/shared/*.ex", "/ws/shared/nested/config.ex")
    end

    test "double star matches nested directories" do
      assert Utils.Path.glob_match?("/ws/docs/**/*.md", "/ws/docs/README.md")
      assert Utils.Path.glob_match?("/ws/docs/**/*.md", "/ws/docs/a/b/README.md")
      refute Utils.Path.glob_match?("/ws/docs/**/*.md", "/ws/docs/a/b/README.txt")
      assert Utils.Path.glob_match?("/ws/docs/**", "/ws/docs/a/b/README.txt")
    end

    test "a matching directory matches all files under it" do
      assert Utils.Path.glob_match?("/ws/native/*", "/ws/native/foo/src/lib.rs")
      refute Utils.Path.glob_match?("/ws/native/*", "/ws/other/foo/src/lib.rs")
    end

    test "question mark, alternatives and character classes" do
      assert Utils.Path.glob_match?("/ws/file?.ex", "/ws/file1.ex")
      refute Utils.Path.glob_match?("/ws/file?.ex", "/ws/file10.ex")

      assert Utils.Path.glob_match?("/ws/*.{ex,exs}", "/ws/config.exs")
      assert Utils.Path.glob_match?("/ws/*.{ex,exs}", "/ws/config.ex")
      refute Utils.Path.glob_match?("/ws/*.{ex,exs}", "/ws/config.eex")
      assert Utils.Path.glob_match?("/ws/a,b", "/ws/a,b")

      assert Utils.Path.glob_match?("/ws/file[12].ex", "/ws/file2.ex")
      refute Utils.Path.glob_match?("/ws/file[12].ex", "/ws/file3.ex")
    end

    test "special regex characters are escaped" do
      assert Utils.Path.glob_match?("/ws/c++/(lib).ex", "/ws/c++/(lib).ex")
      refute Utils.Path.glob_match?("/ws/a.ex", "/ws/aXex")
    end

    test "paths are expanded" do
      assert Utils.Path.glob_match?("/ws/project/../shared/*.ex", "/ws/shared/config.ex")
      assert Utils.Path.glob_match?("/ws/shared", "/ws/project/../shared/config.ex")
    end
  end

  describe "glob_to_regex/2 with a literal base" do
    defp match?(pattern, base, path),
      do: Regex.match?(Utils.Path.glob_to_regex(pattern, base), path)

    test "wildcard characters in the base are matched literally" do
      assert match?("/ws[1]/shared", "/ws[1]/bar", "/ws[1]/shared/config.exs")
      refute match?("/ws[1]/shared", "/ws[1]/bar", "/ws1/shared/config.exs")

      assert match?("/ws/pkgs[1]/shared", "/ws/pkgs[1]/bar", "/ws/pkgs[1]/shared/a.ex")
      assert match?("/ws{1/shared/*.ex", "/ws{1/bar", "/ws{1/shared/a.ex")
    end

    test "the pattern after the base is still a glob" do
      assert match?("/ws[1]/native/**/*.rs", "/ws[1]/bar", "/ws[1]/native/src/lib.rs")
      refute match?("/ws[1]/native/**/*.rs", "/ws[1]/bar", "/ws[1]/native/src/lib.ex")
    end

    test "unbalanced braces and brackets are matched literally" do
      assert Utils.Path.glob_match?("/ws/foo{bar", "/ws/foo{bar/a.ex")
      assert Utils.Path.glob_match?("/ws/foo[bar", "/ws/foo[bar/a.ex")
      refute Utils.Path.glob_match?("/ws/foo[bar", "/ws/foob/a.ex")
    end

    test "a pattern within the base is matched literally" do
      assert match?("/ws[1]", "/ws[1]/bar", "/ws[1]/shared/a.ex")
      refute match?("/ws[1]", "/ws[1]/bar", "/ws1/shared/a.ex")
    end
  end
end
