%Workspace.Config{
  checks: [
    [
      check: Workspace.Checkers.ValidatePath,
      description: "check deps_path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "deps"
      ]
    ]
  ]
}
