# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

* Support getting option value from an environment variable, through the `:env` option. Used
only if not provided by the user in the CLI arguments.

* Support grouping options in the docs by section. You can now specify the `:doc_section`
to any option, and pass a `:sections` option in the `CliOptions.docs/2` function for the
headers and extended docs of each section.

## [v0.1.1](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.1) (2024-07-04)

### Added

* If an option is set with `doc: false` it is not included in docs.
* Support deprecating options with `:deprecated`.

## [v0.1.0](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.0) (2024-05-13)

Initial release.
