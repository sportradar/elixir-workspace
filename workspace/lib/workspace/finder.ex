defmodule Workspace.Finder do
  @moduledoc false

  # Module responsible for finding projects under a workspace root.

  @default_ignored_paths [".git", "_build", ".elixir_ls"]

  @doc """
  Find all nested mix projects under the given path.

  ## Options

  * `:ignore_paths` - list of paths to ignore
  * `:ignore_projects` - list of projects to ignore
  """
  @spec projects(path :: String.t(), opts :: keyword()) :: [Workspace.Project.t()]
  def projects(workspace_path, opts) do
    ignored_paths = Keyword.fetch!(opts, :ignore_paths) ++ @default_ignored_paths

    projects =
      workspace_path
      |> mix_projects(ignored_paths)
      |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
      |> Enum.filter(&ignored_project?(&1, opts[:ignore_projects]))

    projects
  end

  # if the workspace is in a git repository the mix files are listed by git, which
  # respects the .gitignore rules and avoids walking the whole tree, otherwise the
  # workspace directories are scanned recursively
  defp mix_projects(workspace_path, ignored_paths) do
    case git_mix_files(workspace_path) do
      {:ok, mix_files} ->
        Workspace.Cli.debug("detecting projects from the git mix.exs files")

        mix_files
        |> Enum.map(&Path.dirname/1)
        |> Enum.reject(fn path ->
          path == workspace_path or ignored_path?(path, ignored_paths, workspace_path)
        end)
        |> outermost_paths()

      :error ->
        nested_mix_projects(workspace_path, ignored_paths, workspace_path)
    end
  end

  # tracked and untracked but not ignored mix.exs files of the workspace, if git
  # does not list the workspace's own mix.exs, e.g. the workspace is not in a git
  # repository or it is ignored, git cannot be used
  defp git_mix_files(workspace_path) do
    with {:ok, root} <- Workspace.Git.root(cd: workspace_path),
         {:ok, mix_files} <- repo_mix_files(workspace_path, root),
         true <- Path.join(workspace_path, "mix.exs") in mix_files do
      {:ok, mix_files}
    else
      _other -> :error
    end
  end

  # the mix files under path of the repository with the given root, including the
  # ones of its initialized submodules and of the nested repositories which are
  # not ignored, since git ls-files does not list their files
  defp repo_mix_files(path, root) do
    # nested repositories are listed as untracked directories, e.g. "path/", and
    # they are the only entries matching the directories pathspec
    with {:ok, entries} <-
           Workspace.Git.files(cd: path, pathspec: [":(glob)**/mix.exs", ":(glob)**/"]),
         {:ok, submodules} <- submodules(path, root) do
      {nested_repos, files} = Enum.split_with(entries, &String.ends_with?(&1, "/"))

      mix_files =
        files
        |> Enum.map(&Path.join(path, &1))
        # deleted files that are not staged yet are still listed
        |> Enum.filter(&File.regular?/1)

      {submodules, uninitialized} =
        submodules |> Enum.map(&Path.join(path, &1)) |> Enum.split_with(&repo_root?/1)

      Enum.each(uninitialized, &warn_uninitialized_submodule/1)
      nested_repos = Enum.map(nested_repos, &Path.join(path, &1))

      nested_mix_files =
        Enum.flat_map(submodules ++ nested_repos, fn repo ->
          case repo_mix_files(repo, repo) do
            {:ok, files} -> files
            {:error, _reason} -> []
          end
        end)

      {:ok, mix_files ++ nested_mix_files}
    end
  end

  # the index is listed only if the repository has submodules
  defp submodules(path, root) do
    case File.regular?(Path.join(root, ".gitmodules")) do
      true -> Workspace.Git.submodules(cd: path)
      false -> {:ok, []}
    end
  end

  # the directory of an uninitialized submodule is empty and belongs to the
  # parent repository
  defp repo_root?(path) do
    File.dir?(path) and Workspace.Git.prefix(cd: path) == {:ok, ""}
  end

  defp warn_uninitialized_submodule(path) do
    IO.warn(
      "submodule #{Path.relative_to_cwd(path)} is not initialized, its projects are not " <>
        "detected, run `git submodule update --init --recursive` to include them",
      []
    )
  end

  # projects nested in other projects, e.g. test fixtures, are not workspace
  # projects, as in the recursive scan which stops at the first project
  #
  # each path is compared against all kept paths, which is quadratic but fine
  # for the number of projects of a workspace
  defp outermost_paths(paths) do
    paths
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.reduce([], fn path, acc ->
      if Enum.any?(acc, &Workspace.Utils.Path.parent_dir?(&1, path)), do: acc, else: [path | acc]
    end)
    |> Enum.reverse()
  end

  defp nested_mix_projects(path, ignore_paths, workspace_path) do
    Workspace.Cli.debug("scanning projects under #{path}")

    subdirs = subdirs(path, ignore_paths, workspace_path)

    projects = Enum.filter(subdirs, &mix_project?/1)
    Workspace.Cli.debug("  #{length(projects)} projects detected")

    remaining = subdirs -- projects

    Enum.reduce(remaining, projects, fn project, acc ->
      acc ++ nested_mix_projects(project, ignore_paths, workspace_path)
    end)
  end

  defp subdirs(path, ignore_paths, workspace_path) do
    path
    |> File.ls!()
    |> Enum.map(fn file -> Path.join(path, file) end)
    |> Enum.filter(fn path ->
      File.dir?(path) and not ignored_path?(path, ignore_paths, workspace_path)
    end)
  end

  defp mix_project?(path), do: File.exists?(Path.join(path, "mix.exs"))

  defp ignored_project?(project, ignore_projects) do
    cond do
      project.module in ignore_projects ->
        false

      true ->
        true
    end
  end

  defp ignored_path?(mix_path, ignore_paths, workspace_path) do
    ignore_paths
    |> Enum.map(fn path -> workspace_path |> Path.join(path) |> Path.expand() end)
    |> Enum.any?(fn path -> Workspace.Utils.Path.parent_dir?(path, mix_path) end)
  end
end
