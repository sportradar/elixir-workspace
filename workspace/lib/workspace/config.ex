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
          checks: [Workspace.Check.Config.t()]
        }

  defstruct ignore_projects: [],
            ignore_paths: [],
            checks: []

  def from_list(config) when is_list(config) do
    with {:ok, config} <- Keyword.validate(config, [:ignore_projects, :ignore_paths, :checks]),
         {:ok, checks} <- load_checks(config[:checks]) do
      {:ok,
       %__MODULE__{
         ignore_projects: Keyword.get(config, :ignore_projects, []),
         ignore_paths: Keyword.get(config, :ignore_paths, []),
         checks: checks
       }}
    else
      {:error, invalid} when is_list(invalid) ->
        {:error, "invalid config options given to workspace config: #{inspect(invalid)}"}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}
    end
  end

  defp load_checks(nil), do: {:ok, []}

  defp load_checks(checks) do
    checks =
      Enum.reduce_while(checks, [], fn check, acc ->
        case Workspace.Check.Config.from_list(check) do
          {:ok, check} -> {:cont, [check | acc]}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    case checks do
      {:error, reason} -> {:error, reason}
      checks -> {:ok, checks}
    end
  end
end
