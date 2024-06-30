defmodule WorkspaceConfig do
  @moduledoc """
  Global helpers to access the common workspace configuration.

  ## Example

    ```elixir
    defmodule WorkspaceSubproject.MixProject do
      use Mix.Project

      def project do
        [
          app: :workspace_subproject,
          version: "0.1.0",
          elixir: "~> 1.15",
          start_permanent: Mix.env() == :prod,
          deps: deps(),
          config_path: WorkspaceConfig.config_path(),
          deps_path: WorkspaceConfig.deps_path(),
          build_path: WorkspaceConfig.build_path(),
          lockfile: WorkspaceConfig.lockfile(),
          workspace: [
            tags: [{:scope, :app}]
          ]
        ]
      end

      # ... rest of the `mix.exs`
    end
    ```
  """

  @type workspace_config :: Keyword.t()
  @type path :: atom() | [atom(), ...]

  @doc """
  Returns the workspace configuration for the root workspace project. It contains all `project/0`
  output from the workspace root project`s `mix.exs`
  """
  @spec workspace_config() :: workspace_config()
  def workspace_config, do: get_workspace_config()

  @doc """
  Returns the workspace config option for the given option name.
  """
  @spec get_workspace_option(path, default) :: value when path: path(), default: value, value: var
  def get_workspace_option(path, default \\ nil), do: get_opt(path, default)

  @doc """
  Returns the workspace root path.
  """
  @spec workspace_root() :: Path.t()
  def workspace_root, do: get_opt([:workspace, :root_path])

  @doc """
  Appends the given path to the workspace root path.
  """
  @spec append_to_workspace_root(Path.t()) :: Path.t()
  def append_to_workspace_root(path), do: path_from_root(path)

  @doc """
  Returns the workspace config path
  """
  @spec config_path() :: Path.t()
  def config_path, do: :config_path |> get_opt() |> path_from_root()

  @doc """
  Returns the workspace deps path.
  """
  @spec deps_path() :: Path.t()
  def deps_path, do: :deps_path |> get_opt() |> path_from_root()

  @doc """
  Returns the workspace build path.
  """
  @spec build_path() :: Path.t()
  def build_path, do: :build_path |> get_opt() |> path_from_root()

  @doc """
  Returns the workspace lockfile path.
  """
  @spec lockfile() :: Path.t()
  def lockfile, do: :lockfile |> get_opt() |> path_from_root()

  @doc """
  Returns the workspace artifacts path. It should be defined in the `:workspace` configuration part as `:artifacts_path`.
  If `artifacts_path` not defined then it returns the workspace root path.
  """
  @spec artifacts_path() :: Path.t() | nil
  def artifacts_path do
    [:workspace, :artifacts_path] |> get_opt([]) |> path_from_root()
  end

  @doc """
  Appends the given path to the artifacts path.
  """
  @spec append_to_artifacts_path(Path.t()) :: Path.t()
  def append_to_artifacts_path(path), do: path_from_artifacts(path)

  ### Private functions

  defp get_workspace_config do
    :workspace_config
    |> Process.get()
    |> case do
      nil -> fetch_workspace_config()
      workspace_config -> workspace_config
    end
  end

  defp cache_workspace_config(workspace_config) do
    Process.put(:workspace_config, workspace_config)
    workspace_config
  end

  # We probably cannot start from the current directory because the current mix project is not settled yet
  defp fetch_workspace_config(dir \\ "..")

  defp fetch_workspace_config("/..") do
    raise """
      Could not find the workspace root.
      Please make sure that you are trying to fetch the workspace root config from a workspace subdirectory.
    """
  end

  defp fetch_workspace_config(dir) do
    absolute_dir_path = Path.expand(dir)

    with true <- mix_project_dir?(absolute_dir_path),
         mix_project_config = fetch_project_config(absolute_dir_path),
         true <- workspace_mix_project?(mix_project_config) do
      #
      workspace = Keyword.fetch!(mix_project_config, :workspace)

      mix_project_config
      |> Keyword.put(:workspace, Keyword.put_new(workspace, :root_path, absolute_dir_path))
      |> cache_workspace_config()
    else
      _ -> [absolute_dir_path, ".."] |> Path.join() |> fetch_workspace_config()
    end
  end

  defp mix_project_dir?(absolute_dir_path) do
    mix_exs_path = Path.join([absolute_dir_path, "mix.exs"])
    File.exists?(mix_exs_path)
  end

  defp fetch_project_config(absolute_dir_path) do
    in_project(absolute_dir_path, fn _module ->
      Mix.Project.config()
    end)
  end

  defp workspace_mix_project?(mix_project_config) do
    mix_project_config
    |> Keyword.get(:workspace, [])
    |> Keyword.get(:type) == :workspace
  end

  defp in_project(mix_project_path, fun) do
    if Path.join([mix_project_path, "mix.exs"]) == Mix.Project.project_file() do
      fun.(Mix.Project.get!())
    else
      Mix.Project.in_project(app_name(mix_project_path), mix_project_path, fun)
    end
  end

  # returns an "app name" for the given mix.exs file, it is the
  # folder name containing the project. We need a consistent app name
  # for each mix.exs in order to avoid warnings for module redefinitions
  # when Mix.project.in_project is used.
  #
  # Notice that in some edge cases if multiple projects in your workspace
  # have the same path this may cause incorrect behaviour. But you can
  # use the unique name check for avoiding such cases.
  defp app_name(mix_project_path) do
    mix_project_path
    |> Path.expand()
    |> Path.basename()
    |> String.to_atom()
  end

  defp get_opt(path, default \\ nil), do: get_in(workspace_config(), List.wrap(path)) || default
  defp path_from_root(path), do: Path.join([workspace_root() | List.wrap(path)])
  defp path_from_artifacts(path), do: Path.join([artifacts_path() | List.wrap(path)])
end
