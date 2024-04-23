# mix workspace.new

Provides a `workspace.new` scaffolding tool as an archive.

## Installation

To install from Hex, run:

```bash
mix archive.install hex workspace_new
```

To build and install it locally, run from within the `workspace_new` path:

```bash
# remove any existing version
mix archive.uninstall workspace_new

# install it from the workspace_new folder
MIX_ENV=prod mix do archive.build, archive.install
```

## Usage

Once the archive is installed you can run:

```bash
mix workspace.new PATH
```

and it will scaffold an empty workspace under `PATH`.

## License

Copyright (c) 2023 Panagiotis Nezis, Sportradar

`:workspace_new` is released under the MIT License. See the [LICENSE](LICENSE) file for more
details.
