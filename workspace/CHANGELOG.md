# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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
