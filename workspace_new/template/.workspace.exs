[
  # Add paths that shall not be considered when generating the workspace graph
  ignore_paths: [],
  
  # Custom workspace checks for linting your mono-repo at a package level. You can
  # enforce things like common build dirs or required project depenendencies. For
  # more details chech the Workspace.Check documentation.
  checks: [
  ],

  # Test coverage settings on the workspace level.
  test_coverage: [
    # projects allowed to fail
    allow_failure: [],
    threshold: 60,
    warning_threshold: 70,
    # add coverage exporters
    exporters: []
  ]
]

