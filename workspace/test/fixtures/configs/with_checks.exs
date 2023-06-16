%Workspace.Config{
  checks: [
    [
      check: Workspace.Checkers.ValidatePath,
      opts: [
        config_attribute: :deps_path,
        expected_path: "deps"
      ]
    ]
  ]
}
