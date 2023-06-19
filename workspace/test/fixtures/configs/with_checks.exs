[
  checks: [
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "check deps_path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "deps"
      ]
    ]
  ]
]
