defmodule Ophion.IRCv3.Parser do
  require Logger

  alias Ophion.IRCv3.Message

  defp unescape_value(nil), do: nil

  defp unescape_value(value) do
    value
    |> String.replace("\\\\", "\\")
    |> String.replace("\\:", ";")
    |> String.replace("\\s", " ")
    |> String.replace("\\r", "\r")
    |> String.replace("\\n", "\n")
  end

  defp parse_params(data) do
    data
    |> String.trim_leading()
    |> parse_params([])
  end

  defp parse_params("", acc), do: Enum.reverse(acc)

  defp parse_params(":" <> trailing, acc), do: Enum.reverse([trailing | acc])

  defp parse_params(data, acc) do
    case String.split(data, " ", parts: 2) do
      [param] ->
        Enum.reverse([param | acc])

      [param, rest] ->
        parse_params(String.trim_leading(rest), [param | acc])
    end
  end

  defp parse(%Message{} = msg, "@" <> data) do
    with [tags, rest] <- String.split(data, " ", parts: 2) do
      tags =
        tags
        |> String.split(";")
        |> Enum.map(fn tag ->
          case String.split(tag, "=", parts: 2) do
            [key, value] -> {key, unescape_value(value)}
            [key] -> {key, nil}
          end
        end)
        |> Enum.into(%{})

      parse(%{msg | tags: tags}, rest)
    else
      [_tags] -> {:error, :invalid_message}
    end
  end

  defp parse(%Message{source: nil, verb: nil} = msg, ":" <> data) do
    with [source, rest] <- String.split(data, " ", parts: 2) do
      parse(%{msg | source: source}, rest)
    else
      [_source] -> {:error, :invalid_message}
    end
  end

  defp parse(%Message{verb: nil} = msg, data) do
    with [verb, rest] <- String.split(data, " ", parts: 2) do
      parse(%{msg | verb: verb}, rest)
    else
      [verb] when byte_size(verb) > 0 ->
        {:ok, %{msg | verb: verb, params: []}}

      [_empty] ->
        {:error, :invalid_message}
    end
  end

  defp parse(%Message{verb: v} = msg, data) when is_binary(v) do
    {:ok, %{msg | params: parse_params(data)}}
  end

  defp parse(%Message{} = _msg, _), do: {:error, :invalid_message}

  def parse(msg) when is_binary(msg) do
    with {:ok, result} <- parse(%Message{}, msg) do
      {:ok, result}
    else
      err -> err
    end
  end

  def parse(_), do: {:error, :invalid_message}
end
