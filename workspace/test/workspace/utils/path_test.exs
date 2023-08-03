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
end
