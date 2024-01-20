defmodule Cascade.Templates.Template do
  @moduledoc false
  @behaviour Cascade.Template

  # Generates a cascade template

  @impl Cascade.Template
  def validate_cli_opts(opts) do
    path =
      Keyword.fetch!(opts, :path)
      |> Path.expand(File.cwd!())

    {:ok, Keyword.put(opts, :path, path)}
  end

  @impl Cascade.Template
  def destination_path(asset_path, _config, opts) do
    Path.join([opts[:path], opts[:name], asset_path])
  end
end
