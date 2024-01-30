defmodule CascadeTest do
  use ExUnit.Case

  defmodule TemplateNoAssets do
    @shortdoc "a template without assets"
    @moduledoc "A demo template without assets"

    use Cascade.Template

    @impl true
    def name, do: :no_assets

    @impl true
    def assets_path, do: Path.expand("invalid_path", __DIR__)
  end

  describe "generate/3" do
    test "raises for a template without assets" do
      assert_raise ArgumentError, ~r/no assets defined for template :no_assets under/, fn ->
        Cascade.generate(:no_assets, "foo")
      end
    end
  end

  describe "template docs" do
  end
end
