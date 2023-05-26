defmodule WorkspaceColors do
  @moduledoc """
  Documentation for `WorkspaceColors`.
  """

  @doc """
  Prints an info (blue) message

  See also `WorkspaceColors.log/4`
  """
  @spec info(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def info(command, message, opts \\ []), do: log(:blue, command, message, opts)

  @doc """
  Prints a success (green) message

  See also `WorkspaceColors.log/4`
  """
  @spec success(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def success(command, message, opts \\ []), do: log(:green, command, message, opts)

  @doc """
  Prints an error (red) message

  See also `WorkspaceColros.log/4`
  """
  @spec error(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def error(command, message, opts \\ []), do: log(:red, command, message, opts)

  @doc """
  Prints a warning (yellow) message

  See also `Mix.Helpers.log/4`
  """
  @spec warning(command :: String.t(), message :: IO.ANSI.ansidata(), opts :: Keyword.t()) :: :ok
  def warning(command, message, opts \\ []), do: log(:yellow, command, message, opts)

  @doc """
  Generic log message with a colored part

  The command part is colored with the given `color`. You can specify in the
  `opts` list the `prefix` which defaults to (`* `) and `suffix` (which
  defaults to ` `) in order to modify the default message appearance.

  Optionally you can pass an `ansilist` similarly to `c:Mix.Shell.info/1` for
  custom formatting of the `message`.
  """
  @spec log(
          color :: atom(),
          command :: String.t(),
          message :: IO.ANSI.ansidata(),
          opts :: Keyword.t()
        ) ::
          :ok
  def log(color, command, message, opts) when is_binary(message) do
    log(color, command, [message], opts)
  end

  def log(color, command, message, opts) when is_list(message) do
    prefix = Keyword.get(opts, :prefix, "* ")
    suffix = Keyword.get(opts, :suffix, " ")
    Mix.shell().info([color, "#{prefix}#{command}#{suffix}", :reset | message])
  end
end
