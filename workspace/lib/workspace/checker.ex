defmodule Workspace.Checker do
  @moduledoc """
  A behaviour for implementing workspace checker.

  ## Introduction

  A checker is responsible for validating that a workspace follows the
  configured rules.

  When your mono-repo grows it is becoming more tedious to keep track with
  all projects and ensure that the same standards apply to all projects. For
  example you may wish to have common dependencies defined across all your
  projects, or common `deps` paths.
  """

  @doc """
  Applies a workspace check on the given projects
  """
  @callback check(workspace :: Workspace.t(), opts :: keyword()) :: [struct()]
end
