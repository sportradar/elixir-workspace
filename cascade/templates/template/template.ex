defmodule <%= module %> do
  @moduledoc false
  use Cascade.Template

  @assets_path Path.expand(Path.join(<%= inspect(relative_assets_to_templates_path) %>, <%= inspect(name) %>), __DIR__) 

  @impl Cascade.Template
  def assets_path, do: @assets_path

  # Generates a cascade template
  @impl Cascade.Template
  def name, do: <%= inspect(String.to_atom(name)) %>

  @impl Cascade.Template
  def args_schema do
    # TODO add the cli args schema or remove the callback if not needed
    []
  end
end
