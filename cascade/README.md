# Cascade

Generate code from templates.

`Cascade` provides an easy to use interface for generating code from a set of
templates. It's main features are:

  - *Templates as code* - all template files are evaluated using `EEx`, the actual
  generation code can be modified by overriding the default implementation.
  - `mix cascade` - a helper mix task for generating code from a template, it
  supports parsing of CLI options, and automatically generated help messages from
  the template file.
  - `mix cascade.help` - automatically generate help for your custom templates,
  similar to `mix help`

## Usage

You can generate a new template under your mix project by running:

```bash
$ mix cascade template -- --name my_template
* creating templates/my_template/PLACEHOLDER.md
* creating lib/cascade/templates/my_template.ex
```

This generates two files:

  - The actual template code, which by default is located under
  `lib/cascade/templates/{template_name}`
  - A sample template `PLACEHOLDER.md` file under `templates/{template_name}`

If you now run `mix cascade.help` you will see the newly added template
in the list of available templates:

```bash
$ mix cascade.help
The following templates are available:

  my_template  # TODO: Add shortdoc
  template     # Generates \a new template

Run mix cascade NAME to generate code from the given template
Run mix cascade.help NAME to see help for a specific template
```

You can generate some code using the `my_template` template by running:

```bash
$ mix cascade my_template
```

This will generate all code associated to the given template. In this case it
will only generate the `PLACEHOLDER.md` which was added by the `mix cascade`
command.

You can check the help message of the newly created template by running:

```bash
$ mix cascade.help my_template
```

### Implementing your template

You are now free to implement your actual template logic. You are able to:

  - Add any asset under the the template's assets folder (in our example
  `templates/my_template`).
  - The assets can be plain files or `EEx` templates. In the latter case
  they will be evaluated during generation.
  - Define a set of CLI arguments that your template expects. `mix cascade`
  will validate these options automatically. Notice that by default the
  `:cli_options` package is used for defining the CLI arguments schema.
  - Implement any custom logic in your template's module.

For more details check the `Cascade.Template` docs.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cascade` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cascade, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cascade>.

## License

Copyright (c) 2023 Panagiotis Nezis, Sportradar

Cascade is released under the MIT License. See the [LICENSE](LICENSE) file for more
details.
