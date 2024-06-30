# mix workspace.new

[![Hex.pm](https://img.shields.io/hexpm/v/workspace_config.svg)](https://hex.pm/packages/workspace_config)
[![hex.pm](https://img.shields.io/hexpm/l/workspace_config.svg)](https://hex.pm/packages/workspace_config)
[![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/workspace_config/index.html)

Provides global helpers as an archive to use in the Workspace sub-projects mix.exs files.

## Installation

To install from Hex, run:

```bash
mix archive.install hex workspace_config
```

To build and install it locally, run from within the `workspace_config` path:

```bash
# remove any existing version
mix archive.uninstall workspace_config

# install it from the workspace_config folder
MIX_ENV=prod mix do archive.build, archive.install
```

## Usage

Once the archive is installed you can use supported functions inside workspace 
sub-projects` `mix.exs` files to get access to the common workspace configuration:

```elixir
defmodule WorkspaceSubproject.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace_subproject,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_path: WorkspaceConfig.config_path(),
      deps_path: WorkspaceConfig.deps_path(),
      build_path: WorkspaceConfig.build_path(),
      lockfile: WorkspaceConfig.lockfile(),
      workspace: [
        tags: [{:scope, :app}]
      ]
    ]
  end

  # ... rest of the file
end
```

## License

Copyright (c) 2023 Panagiotis Nezis, Sportradar, Vladimir Drobyshevskiy

`:workspace_config` is released under the MIT License. See the [LICENSE](LICENSE) file for more
details.
