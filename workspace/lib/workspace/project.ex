defmodule Workspace.Project do
  opts = [
    tags: [
      type: {:list, {:or, [:atom, {:tuple, [:atom, :atom]}]}},
      doc: """
      Tags associated with the current project. A single tags can be either
      an `atom` or a tuple of the form `{atom, atom}`. In the latter case
      this is considered a scoped tag. For example:

      ```elixir
      tags: [:utils, {:scope, :shared}]
      ```
      """,
      required: false,
      default: []
    ]
  ]

  @workspace_config_schema NimbleOptions.new!(opts)

  @moduledoc """
  A struct holding a workspace project info.

  ## Workspace project config

  Each workspace project may optionally have some workspace related settings defined
  in it's `Mix.Project` config. There isn't a comprehensive list of all supported
  options since various plugins or mix tasks may define their own options that can
  be read from this configuration.

  The following are the global workspace supported settings:

  #{NimbleOptions.docs(@workspace_config_schema)}
  """

  alias __MODULE__, as: Project

  @typedoc """
  A project's tag.

  It can either be a single atom or a tuple of atoms. In the latter case
  this is considered a scoped tag.
  """
  @type tag :: atom() | {atom(), atom()}

  @typedoc """
  Struct holding info about a mix project
  """
  @type t :: %Project{
          app: atom(),
          module: module(),
          config: keyword(),
          mix_path: binary(),
          path: String.t(),
          workspace_path: binary(),
          status: :undefined | :unaffected | :modified | :affected,
          root?: nil | boolean(),
          changes: nil | [{Path.t(), Workspace.Git.change_type()}],
          tags: [tag()]
        }

  @enforce_keys [:app, :module, :config, :mix_path, :path, :workspace_path]
  defstruct app: nil,
            module: nil,
            config: [],
            mix_path: nil,
            path: nil,
            workspace_path: nil,
            skip: false,
            status: :undefined,
            root?: nil,
            changes: nil,
            tags: []

  @doc """
  Creates a new project for the given project path.

  The `path` can be one of the following:

  - A path to a `mix.exs` file
  - A path to a project containing a `mix.exs` file

  You can pass both absolute and relative paths. All paths will
  be expanded by default.

  This will raise if the `path` does not correspond to a valid
  mix project.
  """
  @spec new(mix_path :: String.t(), workspace_path :: String.t()) :: t()
  def new(path, workspace_path) do
    mix_path = mix_path(path)
    workspace_path = Path.expand(workspace_path)

    in_project(
      Path.dirname(mix_path),
      fn module ->
        config = evaluate_config(Mix.Project.config())
        new(workspace_path, mix_path, module, config)
      end
    )
  end

  @doc false
  @spec new(
          workspace_path :: binary(),
          mix_path :: binary(),
          module :: module(),
          config :: Keyword.t()
        ) :: t()
  def new(workspace_path, mix_path, module, config) do
    workspace_config = validate_workspace_project_config!(config)

    %__MODULE__{
      app: config[:app],
      module: module,
      config: config,
      mix_path: mix_path,
      path: Path.dirname(mix_path),
      workspace_path: workspace_path,
      tags: workspace_config[:tags]
    }
  end

  # some config settings are defined as functions in order to be lazily
  # evaluated, we evaluate them here since they may be used in checks
  defp evaluate_config(config) do
    for {key, value} <- config do
      {key, maybe_evaluate(value)}
    end
  end

  defp maybe_evaluate(value) when is_function(value, 0), do: value.()
  defp maybe_evaluate(value), do: value

  defp validate_workspace_project_config!(config) when is_list(config) do
    if project_type(config) == :workspace do
      raise ArgumentError,
            "you are not allowed to have nested workspaces, " <>
              "#{inspect(config[:app])} is defined as :workspace"
    end

    workspace_config = config[:workspace] || []

    global_config = Keyword.take(workspace_config, Keyword.keys(@workspace_config_schema.schema))
    global_config = NimbleOptions.validate!(global_config, @workspace_config_schema)

    Keyword.merge(workspace_config, global_config)
  end

  @doc """
  Returns the project type of a project given the mix config.

  The project type is defined under a `:type` attribute in the `:workspace`
  config. It can take an arbitrary value. If set to `:workspace` it indicates
  that the project is a root workspace project.
  """
  @spec project_type(config :: keyword()) :: nil | atom()
  def project_type(config), do: get_in(config, [:workspace, :type])

  @doc """
  Returns a map including the key properties of the given project.

  Only `:app`, `:module`, `:mix_path`, `:path`, `:workspace_path`, `:status`,
  `:root` and `:changes` are included.

  ## Options

  * `:relative` - If set to `true` the paths will be relative with respect to
  the workspace path. Notice that the `workspace_path` attribute will be set to
  `"."` if `relative` is set.
  """
  @spec to_map(project :: t()) :: map()
  def to_map(project, opts \\ []) do
    opts = Keyword.validate!(opts, relative: false)

    changes = Enum.map(project.changes || [], fn {file, _type} -> file end)

    workspace_path =
      case opts[:relative] do
        true -> "."
        false -> project.workspace_path
      end

    %{
      app: Atom.to_string(project.app),
      module: inspect(project.module),
      mix_path: maybe_relative(project.mix_path, project.workspace_path, opts[:relative]),
      path: maybe_relative(project.path, project.workspace_path, opts[:relative]),
      workspace_path: workspace_path,
      status: Atom.to_string(project.status),
      root: project.root?,
      changes: changes,
      tags: Enum.map(project.tags, &format_tag/1)
    }
  end

  defp maybe_relative(path, _workspace_path, false), do: path

  defp maybe_relative(path, workspace_path, true),
    do: Workspace.Utils.Path.relative_to(path, workspace_path)

  @valid_statuses [:undefined, :modified, :affected, :unaffected]

  @doc """
  Sets the status of the given `project`.
  """
  @spec set_status(project :: t(), status :: atom()) :: t()
  def set_status(project, status) when status in @valid_statuses,
    do: %Workspace.Project{project | status: status}

  @doc """
  Flags the given `project` as root project or not.
  """
  @spec set_root(project :: t(), root? :: boolean()) :: t()
  def set_root(project, root?) when is_boolean(root?),
    do: %Workspace.Project{project | root?: root?}

  @doc """
  Marks the given project as `:modified`.

  The `changes` is the list of changed files belonging to the current
  `project` that have changed.

  An exception will be raised if the `changes` list is empty.
  """
  @spec modified(project :: t(), changes :: []) :: t()
  def modified(project, []) do
    raise ArgumentError,
          "Cannot mark #{inspect(project.app)} as modified without any associated changes"
  end

  def modified(project, changes) when is_list(changes) do
    %Workspace.Project{
      project
      | status: :modified,
        changes: changes
    }
  end

  @doc """
  Returns `true` if the project is modified, false otherwise
  """
  @spec modified?(project :: t()) :: boolean()
  def modified?(project), do: project.status == :modified

  @doc """
  Marks the given project as `:affected`.

  A project is considered affected if any of it's dependencies (either
  direct or indirect) is modified.

  Notice that if the project is already marked as `:modified` it's status
  does not change to `:affected` since by default modified projects are
  considered affected.
  """
  @spec affected(project :: t()) :: t()
  def affected(project) when is_struct(project, Workspace.Project) do
    case project.status do
      :modified -> project
      _other -> %__MODULE__{project | status: :affected}
    end
  end

  @doc """
  Returns `true` if the project is affected, `false` otherwise.

  A project is considered `:affected` if it is either modified or indirectly
  affected from a modified dependency.
  """
  @spec affected?(project :: t()) :: boolean()
  def affected?(project), do: project.status in [:modified, :affected]

  # Helper utility function that just gives a mix.exs absolute path
  # from the input path. It does not check if the file actually exists.
  defp mix_path(path) do
    path = Path.expand(path)

    case String.ends_with?(path, "mix.exs") do
      true -> path
      false -> Path.join(path, "mix.exs")
    end
  end

  @doc """
  Runs the given function inside the given project.

  `path` can be one of the following:

  - a path to a `mix.exs` file
  - a path to a folder containing a `mix.exs` file

  Both absolute and relative paths are supported.

  This function will delegate to `Mix.Project.in_project/4`. The `app` name is
  extracted from the project folder name, so it is expected to match the internal
  defined `:app` name in `mix.exs`.

  The return value of this function is the return value of `fun`

  ## Examples

      Mix.Project.in_project("/path/to/my_app/mix.exs", fn module -> module end)
      #=> MyApp.MixProject
  """
  @spec in_project(path :: binary(), fun :: (module() -> result)) :: result when result: term()
  def in_project(path, fun) do
    mix_path = mix_path(path)

    ensure_mix_file!(mix_path)

    if mix_path == Mix.Project.project_file() do
      fun.(Mix.Project.get!())
    else
      Mix.Project.in_project(
        app_name(mix_path),
        Path.dirname(mix_path),
        fun
      )
    end
  end

  @doc """
  Returns the `Mix.Project` config of the given `mix.exs` file.

  The project will be loaded using `Mix.Project.in_project/4`.
  """
  @spec config(mix_path :: binary()) :: keyword()
  def config(mix_path) do
    in_project(mix_path, fn _module -> Mix.Project.config() end)
  end

  @doc """
  Relative path of the project to the workspace
  """
  @spec relative_to_workspace(project :: t()) :: binary()
  def relative_to_workspace(%Project{path: path, workspace_path: workspace_path}),
    do: Workspace.Utils.Path.relative_to(path, workspace_path)

  # returns an "app name" for the given mix.exs file, it is the
  # folder name containing the project. We need a consistent app name
  # for each mix.exs in order to avoid warnings for module redefinitions
  # when Mix.project.in_project is used.
  #
  # Notice that in some edge cases if multiple projects in your workspace
  # have the same path this may cause incorrect behaviour. But you can
  # use the unique name check for avoiding such cases.
  defp app_name(mix_path) do
    mix_path
    |> Path.expand()
    |> Path.dirname()
    |> Path.basename()
    |> String.to_atom()
  end

  @doc """
  Ensures that the given `path` is an existing `mix.exs` file.

  If the file does not exist or the filename is not `mix.exs` it will raise.
  """
  @spec ensure_mix_file!(path :: String.t()) :: :ok
  def ensure_mix_file!(path) do
    cond do
      Path.basename(path) != "mix.exs" ->
        raise ArgumentError, "expected to get a valid path to a `mix.exs` file, got: #{path}"

      not File.exists?(path) ->
        raise ArgumentError, "#{path} does not exist"

      true ->
        :ok
    end
  end

  @doc """
  Returns `true` if the `project` has the given `tag`, `false` otherwise.

  ## Special tags

  - `:*` - matches all tags, it always returns `true`
  """
  @spec has_tag?(project :: t(), tag :: tag()) :: boolean()
  def has_tag?(_project, :*), do: true
  def has_tag?(project, tag), do: Enum.any?(project.tags, fn t -> t == tag end)

  @doc """
  Returns `true` if the `project` has at least one scoped tag with the
  given `scope`, `false` otherwise.
  """
  @spec has_scoped_tag?(project :: t(), scope :: atom()) :: boolean()
  def has_scoped_tag?(project, scope) do
    Enum.any?(project.tags, fn
      {tag_scope, _tag} -> scope == tag_scope
      _other -> false
    end)
  end

  @doc """
  Returns `true` if the `project` has any of the given tags.
  """
  @spec has_any_tag?(project :: t(), tags :: [tag()]) :: boolean()
  def has_any_tag?(project, tags) do
    Enum.any?(tags, fn tag -> has_tag?(project, tag) end)
  end

  @doc """
  Returns all tags with the given `scope`.
  """
  @spec scoped_tags(project :: t(), scope :: atom()) :: [tag()]
  def scoped_tags(project, scope) do
    Enum.filter(project.tags, fn
      {tag_scope, _tag} -> tag_scope == scope
      _other -> false
    end)
  end

  @doc """
  Formats a tag as a binary.
  """
  @spec format_tag(tag :: tag()) :: String.t()
  def format_tag(tag) when is_atom(tag), do: inspect(tag)
  def format_tag({scope, tag}), do: "#{scope}:#{tag}"
end
