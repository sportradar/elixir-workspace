defmodule Workspace.ExportTest do
  use ExUnit.Case

  describe "to_json/1" do
    @tag :tmp_dir
    test "without changes", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        {:ok, workspace} = Workspace.new(tmp_dir)

        json_data = Workspace.Export.to_json(workspace) |> Jason.decode!()

        assert %{
                 "workspace_path" => workspace_path,
                 "projects" => projects
               } = json_data

        assert workspace_path == Path.expand(tmp_dir)

        assert length(projects) == 11

        for project <- projects do
          assert project["changes"] == []
          assert project["status"] == "undefined"
        end

        # with sort set to true
        sorted_json = Workspace.Export.to_json(workspace, sort: true) |> Jason.decode!()

        assert length(sorted_json["projects"]) == 11

        [project | _rest] = sorted_json["projects"]
        assert project["app"] == "package_a"
      end)
    end

    @tag :tmp_dir
    test "relative vs absolute paths", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        # by default we have absolute paths
        {:ok, workspace} = Workspace.new(tmp_dir)

        json_data = Workspace.Export.to_json(workspace) |> Jason.decode!()

        assert Path.type(json_data["workspace_path"]) == :absolute

        for project <- json_data["projects"] do
          assert Path.type(project["workspace_path"]) == :absolute
          assert Path.type(project["mix_path"]) == :absolute
          assert Path.type(project["path"]) == :absolute
        end

        # with relative flag set
        json_data = Workspace.Export.to_json(workspace, relative: true) |> Jason.decode!()

        assert json_data["workspace_path"] == "."

        for project <- json_data["projects"] do
          assert project["workspace_path"] == "."
          assert Path.type(project["mix_path"]) == :relative
          assert Path.type(project["path"]) == :relative
        end
      end)
    end

    @tag :tmp_dir
    test "with workspace changes", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")

          workspace =
            Workspace.new!(tmp_dir)
            |> Workspace.Status.update()

          json_data = Workspace.Export.to_json(workspace) |> Jason.decode!()

          assert %{
                   "projects" => projects
                 } = json_data

          assert length(projects) == 11

          for project <- projects do
            if project["app"] in ["package_d", "package_e"] do
              refute project["changes"] == []
              assert project["status"] == "modified"
            else
              assert project["changes"] == []
              assert project["status"] in ["undefined", "affected"]
            end
          end
        end,
        git: true
      )
    end
  end
end
