[
  ignore_paths: ["artifacts/deps"],
  # TODO: add a required attribute check
  # TODO: allow check to fail with flag
  # TODO: ignore and only projects options
  # TODO: print ignored and successful only with verbose
  checks: [
    [
      module: Workspace.Checkers.ValidateConfigPath,
      description: "all projects must have a common dependencies path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "artifacts/deps"
      ]
    ],
    [
      module: Workspace.Checkers.ValidateConfigPath,
      description: "all projects must have a common build path",
      opts: [
        config_attribute: :build_path,
        expected_path: "artifacts/build"
      ]
    ]
  ]
]
