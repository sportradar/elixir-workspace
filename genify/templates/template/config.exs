[
  name: :new,
  shortdoc: "Generates a new template",
  doc: """
  Generates a new `genify` template.

  TODO: add detailed description

  ## Usage

      # generate a template named ui_component
      mix genify.gen template --path templates --name ui_component
  """,
  module: Genify.Templates.Template,
  args: [
    path: [
      type: :string,
      doc: "The templates path with respect to the current working directory",
      required: true
    ],
    name: [
      type: :string,
      doc: "The template name",
      required: true
    ]
  ]
]
