# Overview

A `workspace` holding the `workspace`.

`Workspace` provides a set of tools for working with **elixir monorepos**.
Using path dependencies between the projects and the provided tools you can
effectively work on massive codebases properly split into reusable packages.

![Demo](https://github.com/sportradar/elixir-workspace/blob/assets/demo.gif)

## Folder Structure

This repository is structured as a workspace, with all internal packages as
top-level folders. The following packages are included:

  * [`workspace`](workspace/README.md) - A toolbox for managing elixir monorepos
  * [`workspace_new`](workspace_new/README.md) - Workspace installer
  * [`cli_options`](cli_options/README.md) - An opinionated cli options parser
  * [`cascade`](cascade/README.md) - A scaffolding library

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution
and development guidelines and our [Code of Conduct](CODE_OF_CONDUCT.md), and then:

  * Fork it (<https://github.com/sportradar/elixir-workspace/fork>)
  * Create your feature branch (`git checkout -b my-new-feature`)
  * Commit your changes (`git commit -am 'Add some feature'`)
  * Push to the branch (`git push origin my-new-feature`)
  * Create a new Pull Request

## License

All packages are licensed under the MIT license. Check the `LICENSE` file of each
package for more details.
