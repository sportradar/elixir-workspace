[
  checks: [
    [
      id: :deps_path,
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a common deps_path set",
      opts: [
        validate: fn _project -> {:ok, "all good"} end
      ]
    ],
    [
      id: :docs_output_path,
      group: :docs,
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a common docs output path",
      opts: [
        validate: fn _project -> {:ok, "all good"} end
      ]
    ],
    [
      id: :source_url,
      group: :docs,
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have the same source_url set",
      opts: [
        validate: fn _project -> {:ok, "all good"} end
      ]
    ],
    [
      id: :coverage,
      group: :tests,
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have coverage threshold of at least 90%",
      opts: [
        validate: fn _project -> {:ok, "all good"} end
      ]
    ]
  ],
  groups_for_checks: [
    docs: [
      style: [:light_cyan],
      title: "## Documentation checks"
    ],
    tests: [
      style: [:yellow],
      title: "## Testing checks"
    ]
  ]
]
