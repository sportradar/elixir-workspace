%Doctor.Config{
  ignore_modules: [
    # ignore false positives
    Cascade.Template,
    Workspace.Coverage
  ],
  ignore_paths: [],
  min_module_doc_coverage: 100,
  min_module_spec_coverage: 100,
  min_overall_doc_coverage: 100,
  min_overall_spec_coverage: 100,
  min_overall_moduledoc_coverage: 100,
  raise: false,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  exception_moduledoc_required: false,
  umbrella: false
}
