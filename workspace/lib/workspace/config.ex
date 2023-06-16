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

  @config_file ".workspace.exs"

  alias __MODULE__

  @type t :: %Config{
          ignore_projects: [module()],
          ignore_paths: [binary()],
          checks: [term()]
        }

  defstruct ignore_projects: [],
            ignore_paths: [],
            checks: []

  @spec load_config_file(config_file :: binary()) :: t()
  def load_config_file(config_file \\ @config_file) do
    config_file = Path.expand(config_file)

    case File.exists?(config_file) do
      false ->
        {:error, "workspace config file #{config_file} not found"}

      true ->
        {%Config{} = config, _bindings} = Code.eval_file(config_file)

        config
    end
  end
end
