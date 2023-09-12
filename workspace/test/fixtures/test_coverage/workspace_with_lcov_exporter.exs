[
  test_coverage: [
    allow_failure: [:package_b, :package_c],
    threshold: 40,
    exporters: [
      lcov: fn workspace, coverage_stats ->
        Workspace.Coverage.LCOV.export(workspace, coverage_stats, output_path: "coverage")
      end
    ]
  ]
]
