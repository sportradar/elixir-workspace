# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Fixed

* Mark projects as modified when their lockfile changes, even if it is outside of the project's path

## [v0.4.0](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.4.0) (2026-09-29)

### Added

* Add `Workspace.Checks.ValidateAffectedBy` check

  Verifies that the `:affected_by` paths of the projects match at least one
  file of the repository and are not within the project's own path. A mistyped
  or stale path would otherwise be silently ignored, and changes that should
  affect the project would not be detected.

  ```elixir
  [
    module: Workspace.Checks.ValidateAffectedBy,
    description: "all affected_by paths must be valid"
  ]
  ```

* Include `:affected_by` paths in the workspace graph

  Each distinct `:affected_by` path is now a `:path` node of the workspace graph,
  shared by all projects declaring it. Affected projects are computed through
  the graph, and the changed files matching each path are recorded in the new
  `:affected_by_changes` project field.

  Paths are rendered by `mix workspace.graph` in all formats, and paths with
  changed files are highlighted when `--show-status` is set:

  ```
  $ mix workspace.graph --show-status
  :api ●
  └── :nif ●
      ├── native/common (path) ✚
      └── proto/*.proto (path)
  :other ●
  └── native/common (path) ✚
  ```

  `mix workspace.status` prints the matched paths and their changed files under
  each project, and they are included under `affected_by_changes` in the JSON
  export of the projects:

  ```
  $ mix workspace.status
  Affected projects:
    :api api/mix.exs
    :nif nif/mix.exs
      affected by native/**/*.rs
        untracked native/src/lib.rs
  ```

### Fixed

* Fix `workspace.status` printing absolute paths for changed files outside of the workspace
* Fix invalid `workspace.graph --format mermaid` output for projects named after mermaid keywords, e.g. `end`
* Fix `Workspace.Test.create_workspace/4` ignoring the `:projects` option and `with_workspace/5` not forwarding its options
* Fix malformed `FNF` and `FNH` function counts in LCOV coverage exports
* Fix `workspace.list --maintainer` skipping projects added with `--include`
* Fix `workspace.graph --format dot` omitting projects without any dependency or dependent
* Fix `workspace.graph --focus` silently printing an empty graph for unknown or excluded projects
* Fix invalid `workspace.graph --format dot` output for projects named after DOT keywords, ids are now quoted
* Fix `workspace.run --export` crashing on task output that is not valid UTF-8
* Fix `workspace.run --export` not writing the results when terminated by `--early-stop`
* Fix `--env-var` rejecting values containing `=` and upper casing the variable names
* Fix `DependenciesVersion` check failing for options in a different order, git `:tag` or `:ref` versions, or projects without deps
* Fix `WorkspaceDepsPaths` check crashing on dependencies without a path, with a version requirement, or projects without deps
* Fix `ValidateConfigPath` check crashing if `:expected_path` is not set, it is now required
* Fix `ValidateConfigPath` check failing for absolute configured or expected paths
* Fix changes of files with non ASCII or special characters in their names not being detected
* Fix git warnings, e.g. about line endings or deprecated config options, hiding changed files or crashing workspace loading
* Fix `--base` including files changed only on the base branch, changes are now computed against the merge base (`base...head`)
* Fix `:ignore_paths` also ignoring paths sharing the same prefix, e.g. `cover` ignored `coverage_tools`

* Support status related operations in repositories without commits

  Detecting the uncommitted files relied on `git diff HEAD`, which fails if
  the repository has no commits yet, so any status related operation, e.g.
  `mix workspace.run --affected`, raised. Staged files are now considered
  uncommitted in this case.

* Reset previous statuses on a forced `Workspace.Status.update/2`

  A forced status update only marked the currently modified and affected
  projects, so statuses and changes from a previous update were kept, e.g. a
  project stayed modified after its changes were reverted, or when re-running
  the update against a different `:base`.

* Detect changes of workspaces under symlinked paths

  The git root was resolved to its real path, while project paths kept the
  symlinked form of the workspace path, so no changed file matched any project.
  For example, workspaces under `/var` on macOS, which links to `/private/var`,
  had no modified or affected projects. The git root now keeps the form of the
  workspace path.

* Match `:affected_by` patterns without accessing the filesystem

  Wildcard patterns were previously expanded with `Path.wildcard/1`, so deleted
  files never matched them, e.g. removing a `.rs` file under a `native/**/*.rs`
  pattern did not mark the project as affected. Patterns are now matched
  directly against the changed paths.

## [v0.3.2](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.3.2) (2026-08-05)

### Added

* Add `--include` / `-i` option for union-based filtering

  The `--include` option allows you to add projects back to the filtered set,
  even if they were filtered out by other flags. This acts as a union operation,
  enabling powerful filtering combinations.

  Available in `workspace.run` and `workspace.list` tasks.

  Example use cases:

  - Run tests on affected projects but always include critical services:
  
    ```bash
    mix workspace.run -t test --affected --include auth --include payment
    ```

  - Get all dependencies of a project plus the project itself:
  
    ```bash
    mix workspace.list --dependent my_api --include my_api --format json
    ```

  Note: `--exclude` always has the highest priority - excluded projects cannot
  be re-included with `--include`.

* Add `--recursive` option for transitive dependency filtering

  The `--recursive` option enables deep dependency traversal when used with
  `--dependency` or `--dependent` flags, allowing you to work with all
  transitive dependencies instead of just first-level ones.

  Available in `workspace.run` and `workspace.list` tasks.

  Example use cases:

  - Get all projects that transitively depend on a shared library:
  
    ```bash
    mix workspace.list --dependency shared_utils --recursive
    ```

  - Run tests on all transitive dependencies of an API service:
  
    ```bash
    mix workspace.run -t test --dependent my_api --recursive
    ```

  - Find all projects affected by changes to a core dependency:
  
    ```bash
    mix workspace.list --dependency core_lib --recursive --format json
    ```

  By default (without `--recursive`), `--dependency` and `--dependent` only
  consider direct (first-level) dependencies to maintain backward compatibility.

### Fixed

* Fix `--exclude-tag` having no effect

  The tags provided through the command line were not normalized to atoms
  (or `{scope, tag}` tuples for scoped tags), so they never matched the
  projects' tags and no project was excluded. This affected all tasks
  supporting the option, e.g. `workspace.run`, `workspace.list`,
  `workspace.check` and `workspace.test.coverage`.

## [v0.3.1](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.3.1) (2025-10-24)

### Fixed

* Fix type violation warnings on Elixir 1.19

## [v0.3.0](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.3.0) (2025-10-13)

### Added

* Add `:affected_by` option for explicit project dependencies

  Enables projects to declare dependencies on files outside their directory
  structure, addressing common monorepo scenarios where projects depend
  on shared resources that cannot be detected through mix dependencies.

  In order to explicitly declare dependencies, you can now add in your
  `:workspace` config in the project's `mix.exs`:

  ```elixir
  def project do
  [
    app: :web,
    # ... other config
    workspace: [
      affected_by: [
        "../shared/config.ex",
        "../docs/**/*.md",
        "../rust/foo/"
      ]
    ]
  ]
  end
  ```

  Use cases include

  - Cross-language dependencies (e.g., Rust NIFs depending on Rust crates)
  - Shared configuration files across multiple projects
  - Documentation changes that affect project builds

### Deprecated

* Add `--format` option to `workspace.list` with support for `json` and `pretty` output formats

  The new `--format` option provides a more flexible way to control output format:
  - `--format json` outputs JSON data (replaces the deprecated `--json` flag)
  - `--format pretty` outputs human-readable format (default)
  
  The `--json` option is now deprecated and will be removed in version 0.4.0.
  Use `--format json` with `--output` instead for the same functionality.

## [v0.2.2](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.2.2) (2025-07-10)

### Added

* `workspace.run`: store task output in the exported `json`.

* `workspace.run`: include the task duration in milliseconds in the exported `json`.

* `workspace.list`: support `--base`, `--head`, `--affected` and `---modified` options.

* `workspace.test.coverage`: allow filtering by package path.

## [v0.2.1](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.2.1) (2025-03-14)

* Allow having multiple workspaces under the same git repo.

## [v0.2.0](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.2.0) (2025-02-07)

**This version requires at least elixir v1.16**

### Added

* `workspace.run`: support specifying execution order through the `--option` flag.

  Till now `workspace.run` was executing the tasks in alphabetical order. A new `--order`
  cli option is added that support setting it to `preorder`. This will perform a
  depth first search on the project graph and return the projects in post-order, e.g.
  outer leaves are returned first respecting the topology of your workspace.

* `workspace.run`: support filtering by root paths through the `--path` flag.

* `workspace.run`: support filtering by `--dependency` and `--dependent` similarly
to `workspace.list`.

* Support passing most repeated CLI arguments as a comma separated list, for
  example you can now do:

  ```bash
  $ mix workspace.run -t format -p p1,p2,p3
  ```

* `workspace.check`: support running specific checks through the `--check` option
* `workspace.check`: support grouping checks.

  You can now configure the group of each check in your workspace config, with the
  `group` option. Checks with the same group will be printed together on the CLI output,
  under a group header.

  Additionally you can specify `groups_for_checks` with which you can modify the default
  look and feel of each check group, for example:

  ```elixir
  groups_for_checks: [
    package: [
      style: [:light_blue_background, :black],
      title: " 📦 Package checks"
    ],
    documentation: [
      style: [:yellow_background, :black],
      title: " 📚 Documentation checks"
    ]
  ]
  ```

* `workspace.list`: support filtering by root paths through the `--path` flag.

* Promoted helper testing utilities to a `Workspace.Test` module.

### Deprecated

* Check definitions without an `id` is deprecated. ids can be used for filtering
  the checks that will be executed.

### Removed

* `Workspace.Utils.Path.relative_to/2` has been removed. After requiring at least
elixir 1.16 you can now use `Path.relative_to/3` instead with the `force: true`
option.

### Fixed

* Escape base and head references in git commands.

* `workspace.test.coverage`: respect `ignore_modules` from coverage report

## [v0.1.2](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.1.2) (2024-09-30)

### Added

* `workspace.list`: support filtering by dependents through the `--dependent` flag. You
can now list all projects that are direct dependencies of a given project:

  ```bash
  mix workspace.list --dependent my_project
  ```

* `workspace.list`: support filtering by dependencies through the `--dependency`. Using this
flag you can list only those projects that have the given direct dependency:

  ```bash
  mix workspace.list --dependency a_project
  ```

* `workspace.list`: add `--maintainer` for filtering projects with the given maintainer

## [v0.1.1](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.1.1) (2024-07-04)

### Added

* `workspace.run`: add `--export` option for exporting execution results as a `json`
file
* `workspace.run`: log execution time per project
* `workspace.list`: add `--relative-paths` option for exporting relative paths with
respect to the workspace path instead of absolute paths (the default one).

### Removed

* `workspace.run`: remove `--execution-mode` flag

## [v0.1.0](https://github.com/sportradar/elixir-workspace/tree/workspace/v0.1.0) (2024-05-13)

Initial release.
