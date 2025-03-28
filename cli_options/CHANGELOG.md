# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.1.5](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.5) (2025-03-28)

### Fixed

* Support `allowed` flag when `multiple` is set to `true`.

## [v0.1.4](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.4) (2025-02-07)

### Added

* Support defining mutually exclusive arguments through `:conflicts_with` option.

  ```cli
  schema = [
    verbose: [type: :boolean, conflicts_with: [:silent]],
    silent: [type: :boolean]
  ]

  CliOptions.parse(["--verbose", "--silent"], schema)
  >>>
  ```

* Support post validation of the parsed options in `CliOptions.parse/3`  through an
  optional `:post_validate` option.

  ```cli
  schema = [
    silent: [type: :boolean],
    verbose: [type: :boolean]
  ]

  # the flags --verbose and --silent should not be set together
  post_validate =
    fn {opts, args, extra} ->
      if opts[:verbose] and opts[:silent] do
        {:error, "flags --verbose and --silent cannot be set together"}
      else
        {:ok, {opts, args, extra}}
      end
    end

  # without post_validate
  CliOptions.parse(["--verbose", "--silent"], schema)
  >>>

  # with post_validate
  CliOptions.parse(["--verbose", "--silent"], schema, post_validate: post_validate)
  >>>

  # if only one of the two is passed the validation succeeds
  CliOptions.parse(["--verbose"], schema, post_validate: post_validate)
  >>>
  ```

## [v0.1.3](https://github.com/sportradar/elixir-workspace/tree/cli_options/v0.1.3) (2024-10-18)

### Added

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
