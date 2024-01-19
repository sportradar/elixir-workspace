defmodule Genify.Templates.Template do
  @moduledoc false

  # Generates a genify template

  def post_process_cli_opts(opts) do
    path =
      Keyword.fetch!(opts, :path)
      |> Path.expand(File.cwd!())

    {:ok, Keyword.put(opts, :path, path)}
  end

  def destination_path(asset_path, config, opts) do
    Path.join([opts[:path], opts[:name], asset_path])
  end
end
