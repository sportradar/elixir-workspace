[
  checks: [
    [
      id: :deps_path,
      module: Workspace.Checks.ValidateConfigPath,
      description: "check deps_path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "deps"
      ]
    ],
    [
      id: :fail_b,
      module: Workspace.Checks.ValidateProject,
      description: "fail on package b",
      opts: [
        validate: fn project ->
          case project.config[:app] do
            :package_b -> {:error, "invalid package"}
            :package_f -> {:ok, ""}
            _other -> {:ok, "no error"}
          end
        end
      ],
      allow_failure: [:package_b]
    ],
    [
      id: :always_fails,
      module: Workspace.Checks.ValidateProject,
      description: "always fails",
      opts: [
        validate: fn _project -> {:error, "this always fails"} end
      ],
      allow_failure: true
    ],
    [
      id: :never_fails,
      module: Workspace.Checks.ValidateProject,
      description: "never fails",
      opts: [
        validate: fn _project -> {:ok, "never fails"} end
      ]
    ]
  ]
]
