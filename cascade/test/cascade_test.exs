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
    def pre_generate(output_path, _opts) do
      send(self(), {:pre_generate, output_path})
    end

    @impl true
    def post_generate(output_path, _opts) do
      send(self(), {:post_generate, output_path})
    end
  end

  defmodule TemplateWithArgs do
    use Cascade.Template

    @impl true
    def name, do: :with_args

    @impl true
    def assets_path, do: Path.expand("tmp/with_args", __DIR__)

    @impl true
    def args_schema do
      [
        name: [type: :string, required: true],
        greeting: [type: :string, default: "Hello"],
        loud: [type: :boolean]
      ]
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

      # callbacks get the expanded path even if a relative one is given
      relative_path = Path.relative_to_cwd(tmp_dir)
      capture_io(fn -> Cascade.generate(:custom_callbacks, relative_path, name: "Elixir") end)

      expected_file = Path.join(tmp_dir, "hello.md")

      assert File.exists?(expected_file)
      assert File.read!(expected_file) == "Hello Elixir\n"

      assert_received {:pre_generate, ^tmp_dir}
      assert_received {:post_generate, ^tmp_dir}
    end
  end

  describe "generate/3 arguments" do
    setup do
      path = Path.join(@assets_path_tests, "with_args/hello.md")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "<%= greeting %> <%= name %> <%= loud %>")
    end

    @tag :tmp_dir
    test "defaults are applied to both cli arguments and options", %{tmp_dir: tmp_dir} do
      cli_path = Path.join(tmp_dir, "cli")
      capture_io(fn -> Cascade.generate(:with_args, cli_path, ["--name", "Elixir"]) end)
      assert File.read!(Path.join(cli_path, "hello.md")) == "Hello Elixir false"

      opts_path = Path.join(tmp_dir, "opts")
      capture_io(fn -> Cascade.generate(:with_args, opts_path, name: "Erlang") end)
      assert File.read!(Path.join(opts_path, "hello.md")) == "Hello Erlang false"
    end

    @tag :tmp_dir
    test "heex assets are not formatted as elixir code", %{tmp_dir: tmp_dir} do
      heex = ~s(<div class="greeting"><%= name %></div>\n)
      File.write!(Path.join(@assets_path_tests, "with_args/page.html.heex"), heex)

      capture_io(fn -> Cascade.generate(:with_args, tmp_dir, name: "Elixir") end)

      assert File.read!(Path.join(tmp_dir, "page.html.heex")) ==
               ~s(<div class="greeting">Elixir</div>\n)
    end

    @tag :tmp_dir
    test "existing files are overwritten only if confirmed or forced", %{tmp_dir: tmp_dir} do
      Mix.shell(Mix.Shell.Process)
      on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

      path = Path.join(tmp_dir, "hello.md")
      File.write!(path, "user edits")

      send(self(), {:mix_shell_input, :yes?, false})
      Cascade.generate(:with_args, tmp_dir, name: "Elixir")
      assert File.read!(path) == "user edits"

      send(self(), {:mix_shell_input, :yes?, true})
      Cascade.generate(:with_args, tmp_dir, name: "Elixir")
      assert File.read!(path) == "Hello Elixir false"

      File.write!(path, "user edits")
      Cascade.generate(:with_args, tmp_dir, [name: "Elixir"], force: true)
      assert File.read!(path) == "Hello Elixir false"
    end

    @tag :tmp_dir
    test "templates can be generated directly", %{tmp_dir: tmp_dir} do
      capture_io(fn ->
        Cascade.Template.generate(TemplateWithArgs, tmp_dir,
          name: "Elixir",
          greeting: "Hi",
          loud: false
        )
      end)

      assert File.read!(Path.join(tmp_dir, "hello.md")) == "Hi Elixir false"
    end

    test "required arguments are validated" do
      assert Cascade.generate(:with_args, "foo", []) == {:error, "option :name is required"}

      assert Cascade.generate(:with_args, "foo", loud: true) ==
               {:error, "option :name is required"}
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
