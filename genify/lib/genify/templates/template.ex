defmodule Genify.Templates.Template do
  @moduledoc false
  @behaviour Genify.Template

  # Generates a genify template

  @impl Genify.Template
  def validate_cli_opts(opts) do
    path =
      Keyword.fetch!(opts, :path)
      |> Path.expand(File.cwd!())

    {:ok, Keyword.put(opts, :path, path)}
  end

  @impl Genify.Template
  def destination_path(asset_path, _config, opts) do
    Path.join([opts[:path], opts[:name], asset_path])
  end
end
