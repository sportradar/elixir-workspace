defmodule Workspace.Utils.Path.PathTest do
  use ExUnit.Case
  doctest Workspace.Utils.Path

  alias Workspace.Utils

  describe "relative_to/2" do
    test "with absolute paths" do
      assert Utils.Path.relative_to("/usr/local/foo", "/usr/local") == "foo"
      assert Utils.Path.relative_to("/usr/local/foo", "/") == "usr/local/foo"
      assert Utils.Path.relative_to("/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Utils.Path.relative_to("/usr/local/foo", "/usr/local/foo") == "."
      assert Utils.Path.relative_to("/usr/local/foo/", "/usr/local/foo") == "."
      assert Utils.Path.relative_to("/usr/local/foo", "/usr/local/foo/") == "."

      assert Utils.Path.relative_to("/etc", "/usr/local/foo") == "../../../etc"
      assert Utils.Path.relative_to(~c"/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Utils.Path.relative_to("/usr/local", "/usr/local/foo") == ".."
      assert Utils.Path.relative_to("/usr/local/..", "/usr/local") == ".."

      assert Utils.Path.relative_to("/usr/../etc/foo/../../bar", "/log/foo/../../usr/") ==
               "../bar"
    end

    test "with relative paths" do
      assert Utils.Path.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"
      assert Utils.Path.relative_to("usr/local/foo", "etc") == "usr/local/foo"

      assert Utils.Path.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"

      # on cwd
      assert Utils.Path.relative_to("foo", File.cwd!()) == "foo"
      assert Utils.Path.relative_to("./foo", File.cwd!()) == "./foo"
      assert Utils.Path.relative_to("../foo", File.cwd!()) == "../foo"

      # both relative
      assert Utils.Path.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"
      assert Utils.Path.relative_to("usr/local/foo", "etc") == "usr/local/foo"
    end
  end

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
end
