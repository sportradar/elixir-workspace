[
  checks: [
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "check deps_path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "deps"
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "fail on package b",
      opts: [
        validate: fn config ->
          case config[:app] do
            :package_b -> {:error, "invalid package"}
            :package_f -> {:ok, ""}
            _other -> {:ok, "no error"}
          end
        end
      ],
      allow_failure: [:package_b]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "always fails",
      opts: [
        validate: fn _config -> {:error, "this always fails"} end
      ],
      allow_failure: true
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "never fails",
      opts: [
        validate: fn _config -> {:ok, "never fails"} end
      ]
    ]
  ]
]
