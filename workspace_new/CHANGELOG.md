# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.3.0](https://github.com/sportradar/elixir-workspace/tree/workspace_new/v0.3.0) (2026-09-29)

### Fixed

* Fix generated workspaces depending on `workspace` v0.2, they now use v0.4
* Fix generated `mix.exs` and `.workspace.exs` not being formatted
* Fix `--app` and `--module` values with a trailing newline passing validation
* Suggest creating projects from within the `packages` folder, which is covered by the generated `.formatter.exs`
* Fix generating a workspace in the current directory when given as `./`
* Raise if more than one path is given, extra arguments were silently ignored

## [v0.2.0](https://github.com/sportradar/elixir-workspace/tree/workspace_new/v0.2.0) (2025-02-07)

* Update generator to use workspace v0.2.0 

* Include `.workspace.exs` and `.formatter.exs` in generated `.formatter.exs`

## [v0.1.0](https://github.com/sportradar/elixir-workspace/tree/workspace_new/v0.1.0) (2024-05-13)

Initial release.
