# Global fixtures
path = TestUtils.create_fixture("sample_workspace", "sample_workspace_run")
TestUtils.make_fixture_unique(path, "default_")

ExUnit.after_suite(fn _stats -> TestUtils.delete_tmp_dirs() end)

ExUnit.start()
