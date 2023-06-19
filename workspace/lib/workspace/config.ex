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

  @type t :: %__MODULE__{
          ignore_projects: [module()],
          ignore_paths: [binary()],
          checks: [keyword()]
        }

  defstruct ignore_projects: [],
            ignore_paths: [],
            checks: []

  @spec from_list(config :: keyword()) :: {:ok, t()} | {:error, binary()}
  def from_list(config) when is_list(config) do
    with {:ok, _config} <- Keyword.validate(config, [:ignore_projects, :ignore_paths, :checks]),
         {:ok, checks} <- load_checks(Keyword.get(config, :checks, [])) do
      {:ok,
       %__MODULE__{
         ignore_projects: Keyword.get(config, :ignore_projects, []),
         ignore_paths: Keyword.get(config, :ignore_paths, []),
         checks: checks
       }}
    else
      {:error, invalid} when is_list(invalid) ->
        {:error, "invalid config options given to workspace config: #{inspect(invalid)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_checks(checks), do: load_checks(checks, [])

  defp load_checks([], acc), do: {:ok, :lists.reverse(acc)}

  defp load_checks([check | rest], acc) do
    result = Workspace.Check.Config.validate(check)

    case result do
      {:ok, check} -> load_checks(rest, [check | acc])
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
    end
  end
end
