defmodule Cascade.UtilsTest do
  use ExUnit.Case

  describe "relative_to/2" do
    test "with absolute paths" do
      assert Cascade.Utils.relative_to("/usr/local/foo", "/usr/local") == "foo"
      assert Cascade.Utils.relative_to("/usr/local/foo", "/") == "usr/local/foo"
      assert Cascade.Utils.relative_to("/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Cascade.Utils.relative_to("/usr/local/foo", "/usr/local/foo") == "."
      assert Cascade.Utils.relative_to("/usr/local/foo/", "/usr/local/foo") == "."
      assert Cascade.Utils.relative_to("/usr/local/foo", "/usr/local/foo/") == "."

      assert Cascade.Utils.relative_to("/etc", "/usr/local/foo") == "../../../etc"
      assert Cascade.Utils.relative_to(~c"/usr/local/foo", "/etc") == "../usr/local/foo"
      assert Cascade.Utils.relative_to("/usr/local", "/usr/local/foo") == ".."
      assert Cascade.Utils.relative_to("/usr/local/..", "/usr/local") == ".."

      assert Cascade.Utils.relative_to("/usr/../etc/foo/../../bar", "/log/foo/../../usr/") ==
               "../bar"
    end

    test "with relative paths" do
      assert Cascade.Utils.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"
      assert Cascade.Utils.relative_to("usr/local/foo", "etc") == "usr/local/foo"

      assert Cascade.Utils.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"

      # on cwd
      assert Cascade.Utils.relative_to("foo", File.cwd!()) == "foo"
      assert Cascade.Utils.relative_to("./foo", File.cwd!()) == "./foo"
      assert Cascade.Utils.relative_to("../foo", File.cwd!()) == "../foo"

      # both relative
      assert Cascade.Utils.relative_to("usr/local/foo", "usr/local") == "usr/local/foo"
      assert Cascade.Utils.relative_to("usr/local/foo", "etc") == "usr/local/foo"
    end
  end

  test "implements_behaviour?/2" do
    assert Cascade.Utils.implements_behaviour?(Cascade.Templates.Template, Cascade.Template)

    refute Cascade.Utils.implements_behaviour?(Cascade, Cascade.Template)
  end
end
