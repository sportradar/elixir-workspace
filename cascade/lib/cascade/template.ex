defmodule Cascade.Template do
  @moduledoc """
  The template generation logic.

  Every `Cascade` template must implement this behaviour. It provides
  callbacks which affect the template generation logic.
  """

  @doc """
  Returns the name of template.

  The names must be unique, it is advised to use a prefix in order to avoid
  collisions with other packages.
  """
  @callback name() :: atom()

  @doc """
  The absolute path to the template.
  """
  @callback assets_path() :: String.t()

  @doc """
  The CLI arguments (if any) schema of the template.

  It should return a valid `CLIOpts` arguments schema. These CLI options will
  be automatically parsed and assigned to the template's bindings when invoked
  from the cascade mix task.

  ## Examples

  ```elixir
  defmodule MyTemplate do
    @behaviour Cascade.Template

    @impl true
    def args_schema do
      [
        path: [
          type: :string,
          doc: "The path to store the template to",
          required: true
        ],
        auth: [
          type: :boolean,
          doc: "Whether to generate authentication logic",
          default: false
        ]
      ]
    end
  end
  ```
  """
  @callback args_schema() :: keyword()

  @doc """
  Used for custom validation and post-processing of cli arguments.

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
  Returns the destination path for the given template file.

  It expects a file path, the template's config and the user provided CLI arguments and
  is expected to return the destination path for this specific asset. The `asset_path` is
  the template file's path with respect to the `assets`. For example for the following
  template:

      templates/foo
      ├── README.md
      ├── lib
      │   └── foo.ex
      └── mix.exs

  it will be called for the following asset paths:

  - `README.md`
  - `mix.exs`
  - `lib/foo.ex`
  """
  @callback destination_path(
              asset_path :: String.t(),
              output_path :: String.t(),
              opts :: keyword()
            ) ::
              String.t()

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :shortdoc, persist: true)

      @behaviour Cascade.Template

      app = Application.get_application(__MODULE__)

      @impl Cascade.Template
      def args_schema, do: []

      @impl Cascade.Template
      def validate_cli_opts(opts), do: {:ok, opts}

      @impl Cascade.Template
      def destination_path(asset_path, output_path, _opts), do: Path.join(output_path, asset_path)

      defoverridable args_schema: 0,
                     validate_cli_opts: 1,
                     destination_path: 3
    end
  end

  @doc """
  Generates a template
  """
  def generate(template, output_path, opts) do
    output_path = Path.expand(output_path)

    for asset <- template_assets(template), not File.dir?(asset) do
      relative_asset_path = Path.relative_to(asset, template.assets_path())
      destination_path = template.destination_path(relative_asset_path, output_path, opts)

      body =
        asset
        |> EEx.eval_file(opts)
        |> maybe_format(destination_path)

      Mix.Generator.create_file(destination_path, body, force: true)
    end
  end

  defp template_assets(template) do
    assets_path = template.assets_path()
    assets = Path.wildcard(Path.join(assets_path, "**"))

    case assets do
      [] ->
        raise ArgumentError,
              "no assets defined for template #{inspect(template.name())} under #{assets_path}"

      assets ->
        assets
    end
  end

  @elixir_extensions [".ex", ".exs", ".heex"]

  defp maybe_format(body, path) do
    extension = Path.extname(path)

    case extension in @elixir_extensions do
      true -> Code.format_string!(body)
      false -> body
    end
  end

  @doc """
  Gets the moduledoc for the given template `module`.

  Returns the moduledoc or `nil`.
  """
  @spec moduledoc(module :: module()) :: String.t() | nil | false
  def moduledoc(module) when is_atom(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} -> moduledoc
      {:docs_v1, _, _, _, :none, _, _} -> nil
      _ -> false
    end
  end

  @doc """
  Gets the shortdoc for the given template `module`.

  Returns the shortdoc or `nil`.
  """
  @spec shortdoc(module :: module()) :: String.t() | nil
  def shortdoc(module) when is_atom(module) do
    case List.keyfind(module.__info__(:attributes), :shortdoc, 0) do
      {:shortdoc, [shortdoc]} -> shortdoc
      _ -> nil
    end
  end
end
