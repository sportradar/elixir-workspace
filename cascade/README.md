# Cascade

Generate code from templates.

`Cascade` provides an easy to use interface for generating code from a set of
templates. It's main features are:

- **Templates as code** - all template files are evaluated using `EEx`, the actual
generation code can be modified by overriding the default implementation. 
- **`mix.cascade`** - a helper mix task for generating code from a template, it
supports parsing of CLI options, and automatically generated help message from
the template file.

## Usage

You can generate a new template under your mix project by running:

```bash
$ mix cascade template -- --name my_template
* creating templates/my_template/README.md
* creating lib/cascade/templates/my_template.ex
```

This generates two files:

- The actual template code, which by default is located under `lib/cascade/template/{template_name}`
- A sample template `README.md` file under `templates/{template_name}`

If you now run `mix cascade.help` you will see the newly added template
in the list of available templates:

```bash
$ mix cascade.help
The following templates are available:

  my_template  #
  template     # Generates a new template
```

You can generate some code using the `my_template` template by running:

```bash
$ mix cascade.help 
```

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

