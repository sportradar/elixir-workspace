# Global fixtures
# 
# these can be used throughout the tests
#
# the following fixtures are created:
#
# `sample_workspace_default` - a copy of the sample workspace fixture with a
# default suffix
# `sample_workspace_changed` - a copy of the sample workspace fixture with some
# files modified for testing the affected related flags
require TestUtils

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_default")
TestUtils.make_fixture_unique(path, "default_")

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_changed")
TestUtils.make_fixture_unique(path, "changed_")
TestUtils.init_git_project(path)
File.touch!(Path.join(path, "package_changed_d/tmp.exs"))
File.touch!(Path.join(path, "package_changed_e/file.ex"))

ExUnit.after_suite(fn _stats -> TestUtils.delete_tmp_dirs() end)

ExUnit.start()
