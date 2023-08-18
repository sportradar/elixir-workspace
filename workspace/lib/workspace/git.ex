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
  @doc """
  Detects the changed git files.

  By default the following files are included:

    - Uncommitted files in the working directory
    - Untracked files in the working directory
    - If `:base` is provided includes:
      - The changed files between `:base` and `HEAD` if no `:head` is set.
      - The changed files between `:base` and `:head` if `:head` is set.


  ## Options

    * `:cd` (`binary()`) - The git repo path, defaults to the current working directory.
    * `:base` (`binary()`) - The base reference to use for comparing to the `HEAD`,
    can be a branch, a commit or any other `git` reference.
    * `:head` (`binary()`) - The `head` to use for comparing to `:base`, if not set
    defaults to `HEAD`. Can be any git reference
  """
  @spec changed_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def changed_files(opts \\ []) do
    with {:ok, uncommitted} <- uncommitted_files(cd: opts[:cd]),
         {:ok, untracked} <- untracked_files(cd: opts[:cd]),
         {:ok, changed} <- maybe_changed_files(opts[:base], opts[:head] || "HEAD", cd: opts[:cd]) do
      changed =
        [uncommitted, untracked, changed]
        |> Enum.concat()
        |> Enum.uniq()
        |> Enum.sort()

      {:ok, changed}
    end
  end

  defp maybe_changed_files(nil, _head, _opts), do: {:ok, []}
  defp maybe_changed_files(base, head, opts), do: changed_files(base, head, opts)

  @doc """
  Returns a list of uncommitted files

  Uncommitted are considered the files that are staged but not committed yet.

  ## Options

    * `:cd` (`binary()`) - The git repo path, defaults to the current working directory.
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

  ## Options

    * `:cd` (`binary()`) - The git repo path, defaults to the current working directory.
  """
  @spec untracked_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def untracked_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    with {:ok, output} <- git_in_path(cd, ~w[ls-files --others --exclude-standard]) do
      {:ok, parse_git_output(output)}
    end
  end

  @doc """
  Get changed files between the given `head` and `base` git references.

  ## Options

    * `:cd` (`binary()`) - The git repo path, defaults to the current working directory.
  """
  @spec changed_files(head :: binary(), base :: binary(), opts :: keyword()) ::
          {:ok, [binary()]} | {:error, binary()}
  def changed_files(head, base, opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    with {:ok, output} <-
           git_in_path(cd, ["diff", "--name-only", "--no-renames", "--relative", base, head]) do
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
