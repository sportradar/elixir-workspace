# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Added

* Add a `--force` option to `mix cascade` for overwriting existing files without asking

### Fixed

* Fix template arguments defaults and required checks not applied for empty arguments or keyword options
* Fix generation failing for `.heex` assets, which were formatted as Elixir code
* Validate the `--name` of the `template` template, invalid names could write files outside the root path
* Fix the default `--templates-path` of the `template` template, it is now based on the app name instead of the current directory
* Reject an absolute `--assets-path` in the `template` template, which generated assets in a wrong location
* Ask before overwriting existing files, they were silently overwritten
* Pass the expanded output path to `c:Cascade.Template.pre_generate/2`, as with `c:Cascade.Template.post_generate/2`
* Fix `Cascade.Checks.check_module_name_validity!/1` accepting names with a trailing newline

## [v0.2.0](https://github.com/sportradar/elixir-workspace/tree/cascade/v0.2.0) (2024-10-21)

Require elixir v1.16

## [v0.1.1](https://github.com/sportradar/elixir-workspace/tree/cascade/v0.1.1) (2024-07-04)

### Added

* Add a `c:Cascade.Template.pre_generate/2` callback to the `Cascade.Template` for
optional setup before template generation.
* Add a `c:Cascade.Template.post_generate/2` callback to the `Cascade.Template` for
post processing generated templates.

## [v0.1.0](https://github.com/sportradar/elixir-workspace/tree/cascade/v0.1.0) (2024-05-13)

Initial release.
