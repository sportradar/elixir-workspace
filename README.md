# WorkspaceEx

**TODO: Add description**

## TODO by priority

### Cleanup

we need to cleanup first in order to make our lifes easier later

- save graph in workspace (to be reconsidered) and make graph functions work with
both a graph and a workspace
- graph exporters make them accept an adjacency list
- move test helpers under lib (only on test env initially) and document them
  properly
- refactor all existing tests and improve test coverage
- document all modules
- make sure lint passes (credo, doctor, dialyzer)

### New features

requirement for each new feature is to be properly documented and
tested

#### Base functionality

- run - allow apps to fail
- graph - dot output
- graph - include external deps
- run - partition support
- run - support custom options per app
- workspace.list support json output
- add workspace.help task with all projects
- add workspace aliases with docs
- coverage - summary output per app
- coverage - json exporter
- coverage - explain module issues

#### cli_opts

- cli_opts handle invalid arguments and raise early
- cli_opts support sections in docs, and update docs function to accept a
  second opts list which will include sections docs

#### checks

- validate config check - support colored returned messages
- validate config check - refactor error handling
- boundaries check support through tags

#### generators - templates

- add a template library
- support generators using template library

#### house keeping - refactoring

- refactor highlight for consistency - introduce helpers
- add a global no-color flag, create helper Cli.info that handles it

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `workspace_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:workspace_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/workspace_ex>.
