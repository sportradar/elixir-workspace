defmodule Workspace.Git do
  @moduledoc """
  Helper git related functions
  """

  @doc """
  Get the git repo root of the given path

  Returns `{:ok, path}` in case of success or `{:error, reason}` in
  case of failure.

  ## Options

  * `:cd` - the path to use for getting the git root, if not
  set defaults to the current working directory.
  """
  @spec root(opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def root(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_in_path(cd, ~w[rev-parse --show-toplevel])
  end

  # TODO enhance once base, head options are supported
  def changed_files(opts \\ []) do
    with {:ok, uncommitted} <- uncommitted_files(cd: opts[:cd]),
         {:ok, untracked} <- untracked_files(cd: opts[:cd]) do
      changed =
        [uncommitted, untracked]
        |> Enum.concat()
        |> Enum.uniq()

      {:ok, changed}
    end
  end

  @doc """
  Returns a list of uncommitted files

  Uncommitted are considered the files that are staged but not committed yet.
  """
  @spec uncommitted_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def uncommitted_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    with {:ok, output} <- git_in_path(cd, ~w[diff --name-only --no-renames HEAD .]) do
      {:ok, parse_git_output(output)}
    end
  end

  @doc """
  Get list of untracked files
  """
  @spec untracked_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def untracked_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    with {:ok, output} <- git_in_path(cd, ~w[ls-files --others --exclude-standard]) do
      {:ok, parse_git_output(output)}
    end
  end

  defp git_in_path(path, git_command) do
    {output, status} =
      File.cd!(path, fn ->
        System.cmd("git", git_command, stderr_to_stdout: true)
      end)

    output = String.trim(output)

    case status do
      0 -> {:ok, output}
      status -> {:error, "git #{Enum.join(git_command, " ")} failed with #{status}: #{output}"}
    end
  end

  defp parse_git_output(output) do
    output
    |> String.split("\n")
    |> Enum.filter(fn file -> file != "" end)
  end
end
