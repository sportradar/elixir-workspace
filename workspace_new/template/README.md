# :<%= app %>

**TODO: Add description**

## Usage

`:<%= app %>` is a mono-repo managed by `Workspace`. You can create packages
using `mix new`.

You can run any command on all packages through `workspace.run` for example:

```bash
mix workspace.run -t format
```

You can add custom workspace checks in `.workspace.exs` and run them by
running:

```bash
mix workspace.check
```

You can use `workspace.graph` or `workspace.status` to see the state of your
workspace:

```bash
mix workspace.graph --show-status
```

For more details check the `Workspace` docs.
