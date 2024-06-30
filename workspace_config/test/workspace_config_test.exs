defmodule WorkspaceConfigTest do
  use ExUnit.Case, async: true

  Code.put_compiler_option(:ignore_module_conflict, true)
  Code.require_file("../lib/workspace_config.ex", __DIR__)

  @workspace_root_path Path.join([__DIR__, "test_workspace"])
  @subproject_path Path.join([@workspace_root_path, "packages", "package"])

  @expected_workspace_config [
                               app: :test_workspace,
                               version: "0.1.0",
                               start_permanent: false,
                               build_embedded: false,
                               build_per_environment: true,
                               build_scm: Mix.SCM.Path,
                               consolidate_protocols: true,
                               erlc_paths: ["src"],
                               erlc_include_path: "include",
                               erlc_options: [],
                               elixir: "~> 1.15",
                               deps: [],
                               elixirc_paths: [],
                               config_path: "config/config.exs",
                               deps_path: "artifacts/deps",
                               build_path: "artifacts/build",
                               lockfile: "workspace.lock",
                               aliases: [],
                               workspace: [root_path: @workspace_root_path, type: :workspace, artifacts_path: "artifacts"]
                             ]
                             |> Enum.sort()

  @expected_config_path Path.join([@workspace_root_path, "config", "config.exs"])
  @expected_deps_path Path.join([@workspace_root_path, "artifacts", "deps"])
  @expected_build_path Path.join([@workspace_root_path, "artifacts", "build"])
  @expected_lockfile Path.join([@workspace_root_path, "workspace.lock"])
  @expected_artifacts_path Path.join([@workspace_root_path, "artifacts"])
  @expected_weird_artifacts_path Path.join([@expected_artifacts_path, "child_directory"])

  @expected_workspace_project_config [
                                       app: :package,
                                       version: "0.2.0",
                                       start_permanent: false,
                                       build_embedded: false,
                                       build_per_environment: true,
                                       build_scm: Mix.SCM.Path,
                                       consolidate_protocols: true,
                                       erlc_paths: ["src"],
                                       erlc_include_path: "include",
                                       erlc_options: [],
                                       elixir: "~> 1.15",
                                       elixirc_options: [ignore_module_conflict: true],
                                       deps: [],
                                       elixirc_paths: ["lib"],
                                       config_path: @expected_config_path,
                                       deps_path: @expected_deps_path,
                                       build_path: @expected_build_path,
                                       lockfile: @expected_lockfile,
                                       my_weird_artifacts: @expected_weird_artifacts_path,
                                       workspace: [tags: [{:scope, :app}]]
                                     ]
                                     |> Enum.sort()

  defmodule T do
    def get_workspace_option, do: WorkspaceConfig.get_workspace_option([:workspace, :type])
    def append_to_workspace_root, do: WorkspaceConfig.append_to_workspace_root("a/long/long/path/to/nowhere")
    def append_to_artifacts_path, do: WorkspaceConfig.append_to_artifacts_path("a/long/long/path/to/nowhere")
  end

  describe "via WorkspaceConfig calls" do
    setup ctx do
      operation = ctx[:operation]
      result = operation && Mix.Project.in_project(:package, @subproject_path, fn _module -> operation.() end)

      [result: result]
    end

    @tag operation: &WorkspaceConfig.workspace_config/0
    test "workspace_config/0 returns the workspace configuration for the root workspace project", ctx do
      assert ctx.result |> sort() == @expected_workspace_config
    end

    @tag operation: &T.get_workspace_option/0
    test "get_workspace_option/2 returns the workspace config option for the given option name", ctx do
      assert ctx.result == :workspace
    end

    @tag operation: &WorkspaceConfig.workspace_root/0
    test "workspace_root/0 returns the workspace root path", ctx do
      assert ctx.result == @workspace_root_path
    end

    @tag operation: &T.append_to_workspace_root/0
    test "append_to_workspace_root/1 returns the combination of the workspace root path and a provided relative path", ctx do
      assert ctx.result == Path.join([@workspace_root_path, "a/long/long/path/to/nowhere"])
    end

    @tag operation: &WorkspaceConfig.config_path/0
    test "config_path/0 returns the workspace config path", ctx do
      assert ctx.result == @expected_config_path
    end

    @tag operation: &WorkspaceConfig.deps_path/0
    test "deps_path/0 returns the workspace deps path", ctx do
      assert ctx.result == @expected_deps_path
    end

    @tag operation: &WorkspaceConfig.build_path/0
    test "build_path/0 returns the workspace build path", ctx do
      assert ctx.result == @expected_build_path
    end

    @tag operation: &WorkspaceConfig.lockfile/0
    test "lockfile/0 returns the workspace lockfile path", ctx do
      assert ctx.result == @expected_lockfile
    end

    @tag operation: &WorkspaceConfig.artifacts_path/0
    test "artifacts_path/0 returns the workspace artifacts path", ctx do
      assert ctx.result == @expected_artifacts_path
    end

    @tag operation: &T.append_to_artifacts_path/0
    test "append_to_artifacts_path/1 returns the combination of the workspace artifacts path and a provided relative path", ctx do
      assert ctx.result == Path.join([@expected_artifacts_path, "a/long/long/path/to/nowhere"])
    end
  end

  describe "via mix.exs" do
    setup ctx do
      operation = ctx[:operation]

      {output, _} = System.cmd("mix", [operation], cd: @subproject_path)

      [result: decode(output)]
    end

    @tag operation: "dummy"
    test "dummy test", ctx do
      assert ctx.result == "Dummy output"
    end

    @tag operation: "workspace_config"
    test "workspace_config/0 returns the workspace configuration for the root workspace project", ctx do
      assert ctx.result |> sort() == @expected_workspace_config
    end

    @tag operation: "workspace_project_config"
    test "workspace_project_config/0 returns the workspace configuration for the root workspace project", ctx do
      assert ctx.result |> Keyword.delete(:aliases) |> sort() == @expected_workspace_project_config
    end

    @tag operation: "get_workspace_option"
    test "get_workspace_option/2 returns the workspace config option for the given option name", ctx do
      assert ctx.result == :workspace
    end

    @tag operation: "workspace_root"
    test "workspace_root/0 returns the workspace root path", ctx do
      assert ctx.result == @workspace_root_path
    end

    @tag operation: "append_to_workspace_root"
    test "append_to_workspace_root/1 returns the combination of the workspace root path and a provided relative path", ctx do
      assert ctx.result == Path.join([@workspace_root_path, "a/long/long/path/to/nowhere"])
    end

    @tag operation: "artifacts_path"
    test "artifacts_path/0 returns the workspace artifacts path", ctx do
      assert ctx.result == @expected_artifacts_path
    end

    defp decode(result) do
      result
      |> Base.decode64!(ignore: :whitespace, padding: false)
      |> :erlang.binary_to_term()
    end
  end

  defp sort(term), do: Enum.sort(term)
end
