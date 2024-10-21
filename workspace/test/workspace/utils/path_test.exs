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
end
