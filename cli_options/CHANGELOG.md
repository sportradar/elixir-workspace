# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.1.3](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.3) (2024-10-18)

* Support providing repeating arguments with a separator. If you set the `separator`
  option for an argument's schema you can pass the values in the format `--arg value1<sep>value2`.
  For example, for the following schema:

  ```elixir
  schema = [
    name: [
      type: :string,
      multiple: true,
      separator: ";" 
    ]
  ```

  all of the following invocation are valid and equivalent:

  ```
  # passing the arg multiple times  
  $ mix foo --name john --name jack --name paul

  # passing the arg once with the values separated with ;
  $ mix foo --name john;jack;paul

  # a combination of the above
  $ mix foo --name john --name jack;paul
  ```

## [v0.1.2](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.2) (2024-07-12)

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
