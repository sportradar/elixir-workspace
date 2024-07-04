defmodule Workspace.ExportTest do
  use ExUnit.Case

  @sample_workspace_changed_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_changed"
                                 )

  describe "to_json/1" do
    test "without changes updated" do
      {:ok, workspace} = Workspace.new(@sample_workspace_changed_path)

      json_data = Workspace.Export.to_json(workspace) |> Jason.decode!()

      assert %{
               "workspace_path" => workspace_path,
               "projects" => projects
             } = json_data

      assert workspace_path == Path.expand(@sample_workspace_changed_path)

      assert length(projects) == 11

      for project <- projects do
        assert project["changes"] == []
        assert project["status"] == "undefined"
      end

      # with sort set to true
      sorted_json = Workspace.Export.to_json(workspace, sort: true) |> Jason.decode!()

      assert length(sorted_json["projects"]) == 11

      [project | _rest] = sorted_json["projects"]
      assert project["app"] == "package_changed_a"
    end

    test "relative vs absolute paths" do
      # by default we have absolute paths
      {:ok, workspace} = Workspace.new(@sample_workspace_changed_path)

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
    end

    test "with changes updated" do
      workspace =
        Workspace.new!(@sample_workspace_changed_path)
        |> Workspace.Status.update()

      json_data = Workspace.Export.to_json(workspace) |> Jason.decode!()

      assert %{
               "projects" => projects
             } = json_data

      assert length(projects) == 11

      for project <- projects do
        if project["app"] in ["package_changed_d", "package_changed_e"] do
          refute project["changes"] == []
          assert project["status"] == "modified"
        else
          assert project["changes"] == []
          assert project["status"] in ["undefined", "affected"]
        end
      end
    end
  end
end
