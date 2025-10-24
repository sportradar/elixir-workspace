# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
