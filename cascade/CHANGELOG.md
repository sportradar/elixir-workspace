# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Fixed

* Fix template arguments defaults and required checks not applied for empty arguments or keyword options
* Fix generation failing for `.heex` assets, which were formatted as Elixir code
* Validate the `--name` of the `template` template, invalid names could write files outside the root path
* Fix the default `--templates-path` of the `template` template, it is now based on the app name instead of the current directory

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
