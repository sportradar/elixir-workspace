defmodule CascadeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule TemplateNoAssets do
    @shortdoc "a template without assets"
    @moduledoc "A demo template without assets"

    use Cascade.Template

    @impl true
    def name, do: :no_assets

    @impl true
    def assets_path, do: Path.expand("invalid_path", __DIR__)
  end

  @assets_path_tests Path.expand("tmp", __DIR__)

  defmodule TemplateCustomCallbacks do
    use Cascade.Template

    @impl true
    def name, do: :custom_callbacks

    @impl true
    def assets_path, do: Path.expand("tmp/custom_callbacks", __DIR__)

    @impl true
    def args_schema, do: [name: [type: :string]]

    @impl true
    def pre_generate(_output_path, _opts) do
      send(self(), :pre_generate)
    end

    @impl true
    def post_generate(_output_path, _opts) do
      send(self(), :post_generate)
    end
  end

  setup do
    on_exit(fn ->
      if File.exists?(@assets_path_tests), do: File.rm_rf!(@assets_path_tests)
    end)
  end

  describe "generate/3" do
    test "raises for a template without assets" do
      assert_raise ArgumentError, ~r/no assets defined for template :no_assets under/, fn ->
        Cascade.generate(:no_assets, "foo")
      end
    end

    @tag :tmp_dir
    test "custom callbacks are called if implemented", %{tmp_dir: tmp_dir} do
      create_asset(Path.join(@assets_path_tests, "custom_callbacks/hello.md"))

      capture_io(fn -> Cascade.generate(:custom_callbacks, tmp_dir, name: "Elixir") end)

      expected_file = Path.join(tmp_dir, "hello.md")

      assert File.exists?(expected_file)
      assert File.read!(expected_file) == "Hello Elixir\n"

      assert_received :pre_generate
      assert_received :post_generate
    end
  end

  defp create_asset(path) do
    File.mkdir_p!(Path.dirname(path))

    content =
      """
      Hello <%= name %>
      """

    File.write!(path, content)
  end
end
