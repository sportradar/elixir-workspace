# Global fixtures
# 
# these can be used throughout the tests
#
# the following fixtures are created:
#
# - `sample_workspace_default` - a copy of the sample workspace fixture with a
# default suffix
# - `sample_workspace_changed` - a copy of the sample workspace fixture with some
# files modified for testing the affected related flags
# - `sample_workspace_committed` - a copy of the sample workspace fixture with some
# changes committed for testing the affected flags
# - `sample_workspace_no_git` - a copy of the sample workspace fixture without a
# git repo initialized
require TestUtils

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_default")
TestUtils.make_fixture_unique(path, "default_")
TestUtils.init_git_project(path)

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_changed")
TestUtils.make_fixture_unique(path, "changed_")
TestUtils.init_git_project(path)
File.touch!(Path.join(path, "package_changed_d/tmp.exs"))
File.touch!(Path.join(path, "package_changed_e/file.ex"))

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_committed")
TestUtils.make_fixture_unique(path, "committed_")
TestUtils.init_git_project(path)
File.touch!(Path.join(path, "package_committed_c/file.ex"))
TestUtils.cmd_in_path(path, "git", ~w[add .])
TestUtils.cmd_in_path(path, "git", ~w[commit -m message])

path = TestUtils.create_fixture("sample_workspace", "sample_workspace_no_git")
TestUtils.make_fixture_unique(path, "no_git_")

ExUnit.after_suite(fn _stats -> TestUtils.delete_tmp_dirs() end)

ExUnit.start()
