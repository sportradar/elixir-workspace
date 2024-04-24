# Contributing

Welcome to the `elixir-workspace` project. Everyone is welcome to contribute. We value
all forms of contributions including code reviews, patches, examples, community
participation, tutorial, and blog posts. In this document, we outline the guidelines
for contributing to the various aspects of the project.

## Overview

All contributions, suggestions, and feedback you submitted are accepted under
the [Project's license](./LICENSE). You represent that if you do not own copyright in the
code that you have the authority to submit it under the [Project's license](./LICENSE).
All feedback, suggestions, or contributions are not confidential. The Project abides
by our [code of conduct](./CODE_OF_CONDUCT.md),

If you send a pull request from a fork, make sure that GitHub actions run successfully.

## Using the issue tracker

The [issue tracker](https://github.com/sportradar/elixir-workspace/issues) should be used
for all workspace related issues. Use it for bugs, questions, proposals and feature
requests, for any of the packages included within the workspace.

  - For small fixes, please feel free to submit a pull request directly.
  - For major changes, please discuss it via an issue first. This will help us coordinate
    our efforts, prevent duplication of work, and help you to craft the change so that it is
    successfully accepted into the project.
  - We actively close unrelated and non-actionable issues to keep the issues tracker tidy.
    We may get things wrong from time to time and will gladly revisit issues, reopening
    when necessary.

Regardless of the kind of issue, please make sure to look for similar existing issues
before posting; otherwise, your issue may be flagged as `duplicate` and closed in favour
of the original one. Also, once you open a new issue, please make sure to **follow the
issue template**.

If you open a question, remember to close the issue once you are satisfied with the answer
and you think there's no more room for discussion. We'll anyway close the issue after some days.

### Looking for a Task to Contribute

You can find [tasks with the "good first issue" label in the issue tracker](https://github.com/sportradar/elixir-workspace/labels/good%20first%20issue).
Please add a comment in issues if you are planning to work on them.

## Development Guide

### Repository Setup

Make sure you have [elixir](https://elixir-lang.org/) and [erlang](https://www.erlang.org/)
installed. You can optionally use a version manager like [asdf](https://asdf-vm.com/).

In order to set up all dependencies, clone the repository and run `make setup`

```sh
git clone https://github.com/sportradar/elixir-workspace.git
cd elixir-workspace
make setup
```

Now you should be able to run and test the code.

### Running tests

You can run all tests by running (in the root folder):

```bash
make test
```

If you want to run all tests of a single project, you can either run `mix test` within
the project's folder, or use the `mix workspace.run` command from the root folder:

```bash
mix workspace.run -t test -p PROJECT_NAME
```

Additionally you can generate the coverage report by running:

```bash
make coverage
```

This runs all workspace tests and requires `genhtml` in order to render the HTML coverage
report.

### Linters

We use various code linters. You can invoke the CI suite by running:

```bash
make ci
```

and the full suite which includes linters note present in the CI, by running:

```bash
make lint
```

Additionally there are `Makefile` targets for each linting step. You can see the full
list of supported commands by running:

```bash
make help
```

### Documentation

Make sure to generate and visually inspect the docs for the package you are working on.
We provide a helper `Makefile` target for generating the Elixir docs:

```bash
$ make docs
```

Additionally we use `markdown` for the high level documenting of the project. In order to
make sure that the markdown files are properly linted run:

```bash
$ make markdown-lint
```

Last we use [`cspell`](https://cspell.org/) to minimize typos. Once you have installed it,
you can invoke it by running:

```bash
$ make spell
```

### Publishing

TODO

## Code of Conduct

Please note that this project is released with a [Code of Conduct][coc].
By participating in this project you agree to abide by its terms.

[coc]: https://github.com/sportradar/elixir-workspace/blob/master/CODE_OF_CONDUCT.md
