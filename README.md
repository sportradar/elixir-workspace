# WorkspaceEx

**TODO: Add description**

## TODO

- cli_opts handle invalid arguments and raise early
- validate config check - support colored returned messages
- validate config check - refactor error handling
- add workspace.list command
- workspace.list support json output
- add a template library
- support generators using template library
- run - support custom options per app
- run - allow apps to fail
- add workspace.help task with all projects
- add workspace aliases with docs
- boundaries check support through tags
- add a forbidden deps check
- refactor highlight for consistency - introduce helpers
- run - partition support
- run - affected support
- graph - dot output
- graph - include external deps
- graph - color code output
- add a global no-color flag, create helper Cli.info that handles it
- coverage - summary output per app
- coverage - json exporter
- coverage - explain module issues

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
