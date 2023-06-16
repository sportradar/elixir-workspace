%Workspace.Config{
  checks: [
    {Workspace.Checkers.ValidatePath,
     [
       config_attribute: :deps_path,
       expected_path: "deps"
     ]}
  ]
}
