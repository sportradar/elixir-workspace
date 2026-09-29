defmodule Workspace.Checks.ValidateAffectedByTest do
  use Workspace.CheckCase
  alias Workspace.Checks.ValidateAffectedBy

  setup do
    {:ok, check} =
      Workspace.Check.validate(id: :test_check, module: ValidateAffectedBy)

    %{check: check}
  end

  @tag :tmp_dir
  test "validates the affected_by paths", %{check: check, tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:valid, "valid", [workspace: [affected_by: ["../shared", "../native/**/*.rs"]]]},
        {:invalid, "invalid", [workspace: [affected_by: ["../shraed", "lib", "../shared"]]]},
        {:none, "none", []}
      ],
      fn ->
        File.mkdir_p!(Path.join(tmp_dir, "shared"))
        File.write!(Path.join(tmp_dir, "shared/config.exs"), "[]")
        File.mkdir_p!(Path.join(tmp_dir, "native/src"))
        File.write!(Path.join(tmp_dir, "native/src/lib.rs"), "// lib")
        Workspace.Test.commit_changes(tmp_dir)

        workspace = Workspace.new!(tmp_dir)
        results = ValidateAffectedBy.check(workspace, check)

        assert_check_status(results, :valid, :ok)

        assert_plain_result(
          results,
          :valid,
          "all :affected_by paths are valid: ../shared, ../native/**/*.rs"
        )

        assert_check_status(results, :invalid, :error)

        assert_plain_result(results, :invalid, [
          "invalid :affected_by paths",
          "../shraed does not match any file",
          "lib is within the project's path"
        ])

        assert_check_status(results, :none, :ok)
        assert_plain_result(results, :none, "no :affected_by paths set")
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "considers untracked but not ignored files", %{check: check, tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:untracked, "untracked", [workspace: [affected_by: ["../shared"]]]},
        {:ignored, "ignored", [workspace: [affected_by: ["../generated"]]]}
      ],
      fn ->
        File.write!(Path.join(tmp_dir, ".gitignore"), "generated/\n")
        File.mkdir_p!(Path.join(tmp_dir, "shared"))
        File.write!(Path.join(tmp_dir, "shared/config.exs"), "[]")
        File.mkdir_p!(Path.join(tmp_dir, "generated"))
        File.write!(Path.join(tmp_dir, "generated/config.exs"), "[]")

        workspace = Workspace.new!(tmp_dir)
        results = ValidateAffectedBy.check(workspace, check)

        assert_check_status(results, :untracked, :ok)
        assert_check_status(results, :ignored, :error)

        assert_plain_result(results, :ignored, [
          "invalid :affected_by paths",
          "../generated does not match any file"
        ])
      end,
      git: true
    )
  end

  test "error if the workspace is not in a git repo", %{check: check} do
    workspace =
      Workspace.Test.workspace_fixture([
        {:foo, "foo", [workspace: [affected_by: ["../shared"]]]},
        {:bar, "bar", []}
      ])

    results = ValidateAffectedBy.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "cannot validate :affected_by paths, the workspace is not in a git repository"
    )

    assert_check_status(results, :bar, :ok)
  end

  test "error if the git files cannot be listed", %{check: check} do
    workspace =
      Workspace.Test.workspace_fixture([{:foo, "foo", [workspace: [affected_by: ["../shared"]]]}])

    # the git root is not a git repository, we need a path outside of the current repo
    no_git_path = Path.join(Workspace.TestUtils.tmp_path(), "affected_by_no_git")
    File.mkdir_p!(no_git_path)
    on_exit(fn -> File.rm_rf!(no_git_path) end)

    workspace = %{workspace | git_root_path: no_git_path}

    results = ValidateAffectedBy.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "cannot validate :affected_by paths, the workspace is not in a git repository"
    )
  end
end
