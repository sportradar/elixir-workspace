[
  # Add paths that shall not be considered when generating the workspace graph
  # By default deps and _build folders are ignored. You are advised to store all
  # build artifacts under a dedicated folder (e.g. artifacts) which should be ignored.
  ignore_paths: ~w[deps _build],
  
  # Custom workspace checks for linting your mono-repo at a package level. You can
  # enforce things like common build dirs or required project depenendencies. For
  # more details chech the `Workspace.Check` documentation.
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

