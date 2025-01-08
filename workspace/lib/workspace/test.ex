defmodule Workspace.Test do
  @moduledoc """
  Convenience helper functions for workspace tests.
  """

  import ExUnit.Assertions

  def create_workspace(path, config, projects) do
    workspace_path = Path.expand(path)

    File.mkdir_p!(workspace_path)

    if File.ls!(workspace_path) != [] do
      raise ArgumentError,
            "cannot create a workspace in a non empty path, #{workspace_path} is not empty"
    end

    # write the workspace mix.exs and .workspace.exs
    File.write!(
      Path.join(workspace_path, "mix.exs"),
      """
      defmodule TestWorkspace.MixProject do
        use Mix.Project
        def project do
          [
            app: :test_workspace,
            elixir: "~> 1.14",
            start_permanent: Mix.env() == :prod,
            elixirc_paths: [],
            workspace: #{inspect(config)}
          ]
        end
      end\
      """
      |> Code.format_string!()
    )

    File.write!(Path.join(workspace_path, ".workspace.exs"), "[]")

    # write the projects
    for {name, path, project_config} <- projects, path = Path.join(workspace_path, path) do
      File.mkdir_p!(path)

      module = Macro.camelize("#{name}") <> ".MixProject"

      config =
        Keyword.merge(
          [
            app: name,
            elixir: "~> 1.14",
            start_permanent: Mix.env() == :prod,
            elixirc_paths: []
          ],
          project_config
        )

      File.write!(
        Path.join(path, "mix.exs"),
        """
        defmodule #{module} do
          use Mix.Project
          def project do
            #{inspect(config)}
          end
        end
        """
        |> Code.format_string!()
        |> Kernel.++(["\n"])
      )

      File.write!(
        Path.join(path, ".formatter.exs"),
        """
        [
          inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
        ]
        """
      )

      # create the lib folder in case any test needs to write a file
      File.mkdir_p!(Path.join(path, "lib"))
    end
  end

  @doc """
  Runs the given `test_fn` in a temporary workspace under the given `path`.

  Projects is expected to be a list of tuples of the form `{name, path, config}`.
  TODO: document default fixtures

  Config is the project config which will be merged with the default:

  ```elixir
  [
    app: name,
    version: "0.1.0",
    elixir: "~> 1.14",
    start_permanent: Mix.env() == :prod,
  ]
  ```
  """
  def with_workspace(path, config, fixture_or_projects, test_fn, opts \\ [])

  def with_workspace(path, config, fixture, test_fn, opts) when is_atom(fixture),
    do: with_workspace(path, config, fixture(fixture), test_fn, opts)

  def with_workspace(path, config, projects, test_fn, opts) do
    config = Keyword.merge(config, type: :workspace)

    fixture_path = Path.expand(path)

    initial_path = :code.get_path()
    previous = :code.all_loaded()

    create_workspace(fixture_path, config, projects)

    try do
      maybe_cd!(fixture_path, opts[:cd], fn ->
        if opts[:git], do: init_git_project(fixture_path)

        test_fn.()
      end)
    after
      :code.set_path(initial_path)

      for {mod, file} <- :code.all_loaded() -- previous,
          file == [] or
            (is_list(file) and List.starts_with?(file, String.to_charlist(fixture_path))) do
        # IO.puts("purging #{mod}")
        :code.purge(mod)
        :code.delete(mod)
        Mix.State.clear_cache()
        # Mix.ProjectStack.clear_stack()
      end

      # IO.puts("deleting fixture path")
      # File.rm_rf!(fixture_path)
    end
  end

  defp fixture(:default) do
    [
      {:package_a, "package_a",
       deps: [
         {:package_b, path: "../package_b"},
         {:package_c, path: "../package_c"},
         {:package_d, path: "../package_d"},
         {:ex_doc, "~> 0.32"}
       ],
       package: [maintainers: ["Jack Sparrow"]],
       workspace: [tags: [:shared, {:area, :core}]]},
      {:package_b, "package_b",
       deps: [
         {:package_g, path: "../package_g"},
         {:foo, "~> 1.0"}
       ],
       description: "a dummy project"},
      {:package_c, "package_c",
       deps: [
         {:package_e, path: "../package_e"},
         {:package_f, path: "../package_f"}
       ]},
      {:package_d, "package_d", deps: []},
      {:package_e, "package_e", deps: []},
      {:package_f, "package_f",
       deps: [
         {:package_g, path: "../package_g"}
       ]},
      {:package_g, "package_g", deps: []},
      {:package_h, "package_h",
       deps: [
         {:package_d, path: "../package_d"}
       ]},
      {:package_i, "package_i",
       deps: [
         {:package_j, path: "../package_j"}
       ]},
      {:package_j, "package_j", deps: []},
      {:package_k, "nested/package_k", deps: []}
    ]
  end

  defp maybe_cd!(fixture_path, true, test_fn), do: File.cd!(fixture_path, test_fn)
  defp maybe_cd!(_fixture_path, _cd, test_fn), do: test_fn.()

  def init_git_project(path) do
    File.cd!(path, fn ->
      System.cmd("git", ~w[init])
      System.cmd("git", ~w[symbolic-ref HEAD refs/heads/main])
      System.cmd("git", ~w[add .])
      System.cmd("git", ~w[commit -m "commit"])
    end)
  end

  def modify_project(workspace_path, project_path) do
    path = Path.join(workspace_path, project_path)

    if not File.exists?(path), do: raise(ArgumentError, "invalid project fixture path: #{path}")

    File.touch!(Path.join(path, "lib/file.ex"))
  end

  def commit_changes(path) do
    File.cd!(path, fn ->
      System.cmd("git", ~w[add .])
      System.cmd("git", ~w[commit -m "changes"])
    end)
  end

  @doc """
  Asserts that the captured cli output matches the expected value with respect to 
  the given options.

  This helper assertion function provides some conveniences for working with cli output assertions:

  ## Options

  - `trim_trailing_newlines` - if set trailing newlines are ignored.

  If no option is set a strict equality check is performed.

  Notice that all trimming operations (if needed) will happen both on the captured,
  and expected strings.
  """
  def assert_captured(captured, expected, opts) do
    captured = sanitize(captured, opts)
    expected = sanitize(expected, opts)

    assert captured == expected
  end

  defp sanitize(string, opts) do
    string
    |> then_if(opts[:trim_trailing_newlines] == true, &String.trim_trailing(&1, "\n"))
  end

  defp then_if(value, true, then_fn), do: then_fn.(value)
  defp then_if(value, false, _then_fn), do: value

  # defp cli_output_to_list(string, opts) do
  #  String.split(string, "\n")
  # end
end
