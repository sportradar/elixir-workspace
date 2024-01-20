defmodule Cascade.Template do
  @moduledoc """
  The template generation logic.

  Every `Cascade` template must implement this behaviour. It provides
  callbacks which affect the template generation logic.
  """

  @doc """
  Used for validating and post-processing cli arguments.

  This can be used for performing custom validations/casting of cli arguments
  and optionally augment them. It expects the parsed cli arguments and is
  expected to return `{:ok, opts}` in case of success or `{:error, reason}`
  in case of failure.

  All templates are required to define the expected cli arguments under their
  `config.exs`. The callback will be called in order to validate the user provided
  arguments.

  ## Examples

  Assuming that you have a template that expects a `--path` argument. Since
  generator works with absolute paths you can override this callback in order
  to expand the path if it is relative.

  ```elixir
  def validate_cli_opts(opts) do
    path =
      Keyword.fetch!(opts, :path)
      |> Path.expand(File.cwd())

    opts = Keyword.put(opts, :path, path)

    {:ok, opts}
  end
  ```
  """
  @callback validate_cli_opts(opts :: keyword()) :: {:ok, keyword()} | {:error, String.t()}


  @doc """
  Returns the destination path for the given asset.

  It expects a file path, the template's config and the user provided CLI arguments and
  is expected to return the destination path for this specific asset. The `asset_path` is
  the template file's path with respect to the `assets`. For example for the following
  template:

  ```bash
  templates/foo
  ├── assets
  │   ├── README.md
  │   ├── lib
  │   │   └── foo.ex
  │   └── mix.exs
  └── config.exs
  ```

  it will be called for the following asset paths:

  - `README.md`
  - `mix.exs`
  - `lib/foo.ex`
  """
  @callback destination_path(asset_path :: String.t(), config :: keyword(), opts :: keyword()) :: String.t()

  # TODO: add a using macro
end
