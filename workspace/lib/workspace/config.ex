defmodule Workspace.Config do
  @moduledoc """
  A struct holding workspace configuration.

  The following configuration options are supported:

  * `:ignore_projects` - List of project modules to be ignored. If set these
  projects will not be considered workspace's projects.
  * `:ignore_paths` - List of paths to be ignored. These paths will not be traversed
  and any child project will not be added to the workspace. Must be relative
  with respect to the workspace root.
  * `:checks` - List of configured checks for the workspace.
  """

  alias __MODULE__

  @type t :: %Config{
          ignore_projects: [module()],
          ignore_paths: [binary()],
          checks: [term()]
        }

  defstruct ignore_projects: [],
            ignore_paths: [],
            checks: []

  @doc """
  Tries to load the given config file.

  The file should be a valid `Workspace.Config` struct. If the file does
  not exist or the contents are not valid, an error will be returned.
  """
  @spec load_config_file(config_file :: binary()) :: {:ok, t()} | {:error, binary()}
  def load_config_file(config_file) do
    config_file = Path.expand(config_file)

    case File.exists?(config_file) do
      false ->
        {:error, "file not found"}

      true ->
        {config, _bindings} = Code.eval_file(config_file)

        validate_config_contents(config)
    end
  end

  defp validate_config_contents(%Config{} = config), do: {:ok, config}

  defp validate_config_contents(_config),
    do: {:error, "invalid contents"}
end
