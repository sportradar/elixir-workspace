defmodule Workspace.Checks.EnforceBoundaries do
  tag_type = {:or, [:atom, {:tuple, [:atom, :atom]}]}

  @schema NimbleOptions.new!(
            tag: [
              type: tag_type,
              doc: "Tag that source project must contain for the rule to be applicable",
              required: true
            ],
            allowed_tags: [
              type: {:list, tag_type},
              default: [:*],
              doc: """
              The source project is allowed to depend on projects that contain at least
              one of these tags. If not set all dependencies are allowed.
              """
            ],
            forbidden_tags: [
              type: {:list, tag_type},
              default: [],
              doc: """
              The source project is forbidden to depend on projects that contain at least
              one of these tags. If not set all dependencies are allowed.
              """
            ]
          )

  @moduledoc """
  Enforces boundaries between projects.

  Workspace provides a generic mechanism in order to express constraints on project
  dependencies using the defined tags. Using this check you can specify rules about
  what internal dependencies are allowed or forbidden.

  Each configured check must specify the `:tag` for which it applies and either a
  set of tags that are allowed to depend on or a set of tags that are forbidden.

  > #### Common use cases {: .tip}
  >
  > When you start paritioning your codebase into multiple well-defined cohesive
  > packages, even for small projects, dozens of packages will be created. If all
  > of them can depend on each other freely, the workspace will become umanageable
  > and you will end up with a [big ball of mud](https://en.wikipedia.org/wiki/Anti-pattern#Big_ball_of_mud).
  >
  > One of the main purposes of the workspace is to help you split your codebase
  > into independent, cohesive and reusable packages. As a side effect you end up
  > with a **clean architecture**.
  >
  > The main purpose of this rule is to enforce the clean architecture and explicitly
  > declare the allowed cross-workspace dependencies.
  >
  > By properly tagging your projects by the architectural layer they belong to,
  > you can apply rules of the form:
  >
  > * `:shared` libraries can only depend on `:shared` libraries
  > * applications can only depend on the business logic layer
  > * applications are not allowed to depend on data layer packages directly

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  You can enforce allowed dependencies for projects with specific tags. For example
  below we enforce that all projects tagged with `{:scope, :shared}` can only depend
  on internal projects with the `{:scope, :shared}` tag.

  ```elixir
  [
    module: Workspace.Checks.EnforceBoundaries,
    description: "shared projects can only depend on shared",
    opts: [
      tag: {:scope, :shared},
      allowed_tags: [{:scope, :shared}]
    ]
  ]
  ```

  Additionally we can forbid specific dependencies, for example:

  ```elixir
  [
    module: Workspace.Checks.EnforceBoundaries,
    description: "public packages cannot depend on admin packages",
    opts: [
      tag: :public,
      forbidden_tags: [:admin]
    ]
  ]
  ```

  By setting multiple boundaries rules you implicitly define your architecture and
  enforce proper dependencies, making the project more maintainable.

  > #### Combination with other checks {: .neutral}
  >
  > It is advised to combine this check with the `Workspace.Checks.ValidateTags` and
  > `Workspace.Checks.RequiredScopeTag` checks in order to:
  >
  > - ensure that all project tags are valid
  > - ensure that all projects are properly scope tagged across the dimensions you
  > have decided to tag upon (`scope`, `team`, `layer` etc)
  > - boundaries are enforced between the various projects
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    Workspace.Check.check_projects(workspace, check, fn project ->
      applicable? = applicable_rule?(project, check[:opts])
      check_rule(project, workspace, check[:opts], applicable?)
    end)
  end

  defp applicable_rule?(project, rule) do
    tag = Keyword.fetch!(rule, :tag)

    case tag do
      :* -> true
      tag -> Workspace.Project.has_tag?(project, tag)
    end
  end

  defp check_rule(project, _workspace, rule, false) do
    Workspace.Cli.debug(
      "not applicable for project #{project.app} - tag #{Workspace.Project.format_tag(rule[:tag])} missing"
    )

    {:ok, [status: :not_applicable]}
  end

  defp check_rule(project, workspace, rule, true) do
    dependencies = Workspace.Graph.dependencies(workspace, project.app)

    with :ok <- validate_allowed_tags(dependencies, workspace, rule),
         :ok <- validate_forbidden_tags(dependencies, workspace, rule) do
      {:ok, dependencies}
    end
  end

  defp validate_allowed_tags(dependencies, workspace, rule) do
    tags = Keyword.fetch!(rule, :allowed_tags)

    invalid =
      Enum.reject(dependencies, fn dependency ->
        project = Workspace.project!(workspace, dependency)
        has_any_tag?(project, tags)
      end)

    case invalid do
      [] -> :ok
      invalid -> {:error, [criterion: :allowed, invalid: invalid, tag: rule[:tag], tags: tags]}
    end
  end

  defp validate_forbidden_tags(dependencies, workspace, rule) do
    tags = Keyword.fetch!(rule, :forbidden_tags)

    invalid =
      Enum.filter(dependencies, fn dependency ->
        project = Workspace.project!(workspace, dependency)
        has_any_tag?(project, tags)
      end)

    case invalid do
      [] -> :ok
      invalid -> {:error, [criterion: :forbidden, invalid: invalid, tag: rule[:tag], tags: tags]}
    end
  end

  defp has_any_tag?(project, tags) do
    Enum.any?(tags, fn tag -> Workspace.Project.has_tag?(project, tag) end)
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    criterion = meta[:criterion]

    error_message(criterion, meta[:tag], meta[:tags], meta[:invalid])
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["no boundaries crossed"]
  end

  defp error_message(:allowed, tag, tags, invalid) do
    [
      "a project tagged with ",
      format_tag(tag),
      " can only depend on projects tagged with ",
      format_tags(tags),
      " - invalid dependencies: ",
      format_deps(invalid)
    ]
    |> List.flatten()
  end

  defp error_message(:forbidden, tag, tags, invalid) do
    [
      "a project tagged with ",
      format_tag(tag),
      " cannot depend on projects tagged with ",
      format_tags(tags),
      " - invalid dependencies: ",
      format_deps(invalid)
    ]
    |> List.flatten()
  end

  defp format_tags(tags) do
    tags
    |> Enum.map(&format_tag/1)
    |> Enum.intersperse(", ")
  end

  defp format_tag(tag), do: [:tag, Workspace.Project.format_tag(tag), :reset]

  defp format_deps(deps) do
    Enum.map(deps, fn dep -> [:project, inspect(dep), :reset] end)
    |> Enum.intersperse(", ")
  end
end
