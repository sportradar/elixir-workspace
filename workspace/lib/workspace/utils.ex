defmodule Workspace.Utils do
  @moduledoc false

  @doc false
  @spec keyword_take!(keywords :: keyword(), keys :: [atom()]) :: keyword()
  def keyword_take!(keywords, keys) when is_list(keywords) and is_list(keys) do
    {take, missing} =
      Enum.reduce(keys, {[], []}, fn key, {take, missing} ->
        case Keyword.has_key?(keywords, key) do
          true -> {[{key, keywords[key]} | take], missing}
          false -> {take, [key | missing]}
        end
      end)

    if missing != [] do
      raise KeyError, key: missing, term: keywords
    end

    take
  end

  @doc false
  @spec digraph_to_mermaid(graph :: :digraph.graph()) :: binary()
  def digraph_to_mermaid(graph) do
    vertices =
      :digraph.vertices(graph)
      |> Enum.map(fn v -> "  #{v}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        {v1, v2}
      end)
      |> Enum.map(fn {v1, v2} -> "  #{v1} --> #{v2}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    """
    flowchart TD
    #{vertices}

    #{edges}
    """
    |> String.trim()
  end

  @doc """
  Formats duration as string
  """
  @spec format_duration(duration :: non_neg_integer(), unit :: :second | :millisecond) ::
          String.t()
  def format_duration(duration, unit \\ :millisecond)

  def format_duration(duration, _unit) when is_integer(duration) and duration < 0 do
    raise ArgumentError, "duration must be a non negative integer, got: #{duration}"
  end

  def format_duration(duration, :second) when is_integer(duration),
    do: format_duration_from_ms(duration * 1000)

  def format_duration(duration, :millisecond) when is_integer(duration),
    do: format_duration_from_ms(duration)

  defp format_duration_from_ms(duration) do
    hour_ms = 60 * 60 * 1_000
    {hours, duration} = {div(duration, hour_ms), rem(duration, hour_ms)}

    minute_ms = 60 * 1_000
    {minutes, duration} = {div(duration, minute_ms), rem(duration, minute_ms)}

    seconds = duration / 1_000

    [
      time_unit(hours, "h"),
      time_unit(minutes, "m"),
      time_unit(Float.round(seconds, 2), "s")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp time_unit(0, _suffix), do: nil
  defp time_unit(num, suffix), do: "#{num}#{suffix}"
end
