defmodule Workspace.Git do
  @moduledoc """
  Helper git related functions
  """

  @type change_type :: :uncommitted | :untracked | :modified

  @doc """
  Get the git repo root of the given path

  Returns `{:ok, path}` in case of success or `{:error, reason}` in
  case of failure.

  If the given path is under a symlinked directory, the symlinked form of the
  root is returned, so that it can be safely compared with paths derived from
  the given path. If the path is itself a symlink pointing inside a repository
  there is no symlinked form of the root and the resolved root is returned.

  ## Options

  * `:cd` - the path to use for getting the git root, if not
  set defaults to the current working directory.
  """
  @spec root(opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def root(opts \\ []) do
    cd = Path.expand(opts[:cd] || File.cwd!())

    command = ~w[rev-parse --show-toplevel --show-prefix]

    # --show-toplevel returns the resolved path, we strip the relative path of
    # cd in the repo (--show-prefix) from cd in order to keep its symlinked form.
    #
    # it is expected to fail outside of a repository, so it is first executed
    # capturing stderr, in order not to print any error to the terminal
    with {:ok, _output} <- git_capturing_stderr(cd, command),
         {:ok, output} <- git_in_path(cd, command) do
      {toplevel, prefix} =
        case String.split(output, "\n") do
          [toplevel] -> {toplevel, ""}
          [toplevel, prefix] -> {toplevel, prefix}
        end

      {:ok, symlinked_root(cd, prefix, toplevel)}
    end
  end

  # the path stripped from its prefix is only a valid root if it is the same
  # directory as the resolved root, e.g. a link with the same name as its
  # target would give a different directory
  defp symlinked_root(cd, prefix, toplevel) do
    case strip_suffix(cd, prefix) do
      nil -> toplevel
      root -> if same_directory?(root, toplevel), do: root, else: toplevel
    end
  end

  defp same_directory?(path, other) do
    %File.Stat{inode: inode, major_device: device} = File.stat!(path)
    %File.Stat{inode: other_inode, major_device: other_device} = File.stat!(other)

    inode == other_inode and device == other_device
  end

  @doc """
  Get the relative path of the given path in its git repository

  Returns `{:ok, prefix}` in case of success, where `prefix` is an empty
  string for the repository root, or `{:error, reason}` in case of failure.

  ## Options

  * `:cd` - the path to get the prefix of, if not set defaults to the
  current working directory.
  """
  @spec prefix(opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def prefix(opts \\ []) do
    cd = Path.expand(opts[:cd] || File.cwd!())

    git_in_path(cd, ~w[rev-parse --show-prefix])
  end

  defp strip_suffix(path, suffix) do
    path = Path.split(path)
    suffix = Path.split(suffix)
    {base, tail} = Enum.split(path, length(path) - length(suffix))

    if tail == suffix, do: Path.join(base), else: nil
  end

  @doc """
  Detects the changed files in the given directory.

  By default the following files are included:

    - Uncommitted files in the working directory
    - Untracked files in the working directory
    - If `:base` is provided it also includes the files changed on `:head` since
    it diverged from `:base`, e.g. `git diff base...head`. `:head` defaults to
    `HEAD` if not set.

  A list of tuples of the form `{"path/to/changed/file", change_type}` is
  returned, where `change_type` can be one of the following:

  * `:uncommitted` - for changed files under version control that are not committed
  * `:untracked` - for new files that are not under version control
  * `:modified` - for changed committed files on `:head` since it diverged from `:base`

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
    * `:base` (`t:binary/0`) - The base reference to use for comparing to the `HEAD`,
    can be a branch, a commit or any other `git` reference.
    * `:head` (`t:binary/0`) - The `head` to use for comparing to `:base`, if not set
    defaults to `HEAD`. Can be any git reference
  """
  @spec changed(opts :: keyword()) ::
          {:ok, [{binary(), change_type()}]} | {:error, binary()}
  def changed(opts \\ []) do
    with {:ok, uncommitted} <- uncommitted_files(cd: opts[:cd]),
         {:ok, untracked} <- untracked_files(cd: opts[:cd]),
         {:ok, changed} <- maybe_changed_files(opts[:base], opts[:head] || "HEAD", cd: opts[:cd]) do
      changed =
        [
          annotate_change(uncommitted, :uncommitted),
          annotate_change(untracked, :untracked),
          annotate_change(changed, :modified)
        ]
        |> Enum.concat()
        |> Enum.sort_by(fn {file, _change} -> file end)

      {:ok, changed}
    end
  end

  defp annotate_change(files, change), do: Enum.map(files, fn file -> {file, change} end)

  defp maybe_changed_files(nil, _head, _opts), do: {:ok, []}
  defp maybe_changed_files(base, head, opts), do: changed_files(base, head, opts)

  @doc """
  Returns a list of uncommitted files

  Uncommitted are considered the files that are staged but not committed yet.

  If the repository has no commits yet, all staged files are considered
  uncommitted.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec uncommitted_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def uncommitted_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    # without any commit HEAD cannot be resolved, so we diff the index instead,
    # we first ensure it is a repository so that other errors are not hidden
    with {:ok, _git_dir} <- git_in_path(cd, ~w[rev-parse --git-dir]) do
      diff_against =
        case git_in_path(cd, ~w[rev-parse --verify --quiet HEAD]) do
          {:ok, _commit} -> "HEAD"
          {:error, _reason} -> "--cached"
        end

      git_files(cd, ~w[diff --name-only --no-renames] ++ [diff_against])
    end
  end

  @doc """
  Returns the files of the repository

  Both tracked files and untracked files which are not ignored are
  included. The paths are relative to the `:cd` path.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
    * `:pathspec` (`t:list/0`) - Only the files matching any of the given git
    pathspecs are returned, defaults to all files.
  """
  @spec files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()
    pathspec = opts[:pathspec] || []

    git_files(cd, ~w[ls-files --cached --others --exclude-standard --] ++ pathspec)
  end

  @doc """
  Returns the submodules of the repository

  The paths of the submodules registered in the index are returned, relative
  to the `:cd` path, whether they are initialized or not. Nested submodules
  are not included.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec submodules(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def submodules(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    # each entry is "<mode> <object> <stage>\t<path>", submodules have the gitlink mode
    with {:ok, entries} <- git_files(cd, ~w[ls-files --stage]) do
      submodules =
        for entry <- entries,
            [info, path] = String.split(entry, "\t", parts: 2),
            String.starts_with?(info, "160000 "),
            uniq: true,
            do: path

      {:ok, submodules}
    end
  end

  @doc """
  Get list of untracked files

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec untracked_files(opts :: keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def untracked_files(opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_files(cd, ~w[ls-files --others --exclude-standard])
  end

  @doc """
  Get the changed files of the `head` git reference since it diverged from `base`.

  The `head` is compared against the merge base of `base` and `head`, e.g.
  changes of `base` after `head` diverged from it are not included. This is
  equivalent to `git diff base...head`.

  ## Options

    * `:cd` (`t:binary/0`) - The git repo path, defaults to the current working directory.
  """
  @spec changed_files(base :: binary(), head :: binary(), opts :: keyword()) ::
          {:ok, [binary()]} | {:error, binary()}
  def changed_files(base, head, opts \\ []) do
    cd = opts[:cd] || File.cwd!()

    git_files(cd, ["diff", "--name-only", "--no-renames", "--relative", "#{base}...#{head}"])
  end

  defp git_in_path(path, git_command) do
    with {:ok, output} <- run_git(path, git_command) do
      {:ok, String.trim(output)}
    end
  end

  # Runs a git command listing files. With -z paths are NUL separated and never
  # quoted, e.g. for non ASCII characters, so they are returned verbatim.
  defp git_files(path, [subcommand | args]) do
    with {:ok, output} <- run_git(path, [subcommand, "-z" | args]) do
      {:ok, output |> String.split(<<0>>) |> Enum.reject(&(&1 == ""))}
    end
  end

  # stderr is not captured, since any git warning, e.g. about line endings or
  # deprecated config options, would be mixed with the parsed output. In case
  # of a failure the command is executed again capturing stderr in order to get
  # the error message.
  defp run_git(path, command) do
    {output, status} = File.cd!(path, fn -> System.cmd("git", command) end)

    case status do
      0 -> {:ok, output}
      status -> git_error(path, command, status)
    end
  end

  defp git_error(path, command, status) do
    {output, _status} =
      File.cd!(path, fn -> System.cmd("git", command, stderr_to_stdout: true) end)

    {:error, "git #{Enum.join(command, " ")} failed with #{status}: #{String.trim(output)}"}
  end

  # the output is mixed with any warnings, it is not meant to be parsed
  defp git_capturing_stderr(path, command) do
    case File.cd!(path, fn -> System.cmd("git", command, stderr_to_stdout: true) end) do
      {output, 0} -> {:ok, output}
      {_output, status} -> git_error(path, command, status)
    end
  end
end
