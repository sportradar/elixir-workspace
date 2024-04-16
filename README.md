# Overview

This repository holds the following projects:

  * [`workspace`](workspace/README.md) - A toolbox for managing elixir monorepos
  * [`workspace_new`](workspace_new/README.md) - Workspace installer
  * [`cli_options`](cli_options/README.md) - An opinionated cli options parser
  * [`cascade`](cascade/README.md) - A scaffolding library 

## Contributing

We invite contributions to `Workspace`. Once you have forked and pulled the
repo you can setup the project by running:

```bash
make setup
```

This will download and compile all external dependencies.

### Running tests

You can run all tests by running (in the root folder):

```bash
make test
```

Alternatively you can use the helper `mix alias` that will only run tests
on affected projects

```bash
mix test
```

If you want to run all tests of a single project, you can use the
`mix workspace.run` command:

```bash
mix workspace.run -t test -p PROJECT_NAME
```

Additionally you can generate the coverage report by running:

```bash
make coverage
```

This runs all workspace tests and requires `genhtml` in order to
render the `HTML` coverage report.

### Linting

In order to run the full linter's suite you can run:

```bash
make lint
```

Additionally we use [`cspell`](https://cspell.org/) for detecting spelling
mistakes. In order to run it (given that you have it installed):

```bash
make spell
```

We use [`markdownlint`](https://github.com/DavidAnson/markdownlint) to lint
`*.md` files. In order to run it:

```bash
make markdown-lint
```

You can see all available `make` commands by running:

```bash
make help
```

### Building documentation

In order to build the documentation run the following from the root folder:

```bash
make docs
```

This will produce `html` documentation for all workspace projects, under
the `artifacts/docs` directory.
