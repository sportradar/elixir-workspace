defmodule TemplateNoDocs do
  @moduledoc false
  use Cascade.Template

  @impl true
  def name, do: :template_no_docs

  @impl true
  def assets_path, do: "../templates"
end

ExUnit.start()
