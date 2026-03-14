defmodule Ophion.IRCv3.Composer do
  @moduledoc """
  Documentation for `Ophion.IRCv3.Composer`.
  """

  alias Ophion.IRCv3.Message

  # XXX: rewrite using iolists for max speed
  def escape_value(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\\:")
    |> String.replace(" ", "\\s")
    |> String.replace("\r", "\\r")
    |> String.replace("\n", "\\n")
  end

  def escape_value(_), do: nil

  defp tag([key]), do: [key]
  defp tag([key, nil]), do: [key]
  defp tag(tval) when is_list(tval), do: [Enum.join(tval, "=")]
  defp tag(_), do: []

  defp tags(input, %Message{tags: %{} = tags}) when map_size(tags) > 0 do
    tag_parts = 
      Enum.reduce(tags, [], fn ({key, value}, acc) ->
        acc ++ tag([key, escape_value(value)])
      end)
      |> Enum.join(";")

    input ++ ["@" <> tag_parts]
  end

  defp tags(input, _), do: input

  defp source(input, %Message{source: src}) when is_binary(src), do: input ++ [":" <> src]
  defp source(input, _), do: input

  defp verb(input, %Message{verb: verb}) when is_binary(verb), do: input ++ [verb]

  defp params(input, %Message{params: params}) when length(params) > 0 do
    {last_param, middle_params} = List.pop_at(params, -1)

    last_param =
      if trailing_param?(last_param) do
        ":" <> last_param
      else
        last_param
      end

    input ++ middle_params ++ [last_param]
  end

  defp params(input, _), do: input

  defp trailing_param?(param) when is_binary(param) do
    param == "" or
      String.starts_with?(param, ":") or
      String.contains?(param, " ")
  end

  def compose(%Message{} = msg) do
    with :ok <- Message.validate(msg) do
      composed =
        tags([], msg)
        |> source(msg)
        |> verb(msg)
        |> params(msg)
        |> Enum.join(" ")

      {:ok, composed <> "\r\n"}
    else
      err -> err
    end
  end

  def compose(_), do: {:error, :invalid_message}
end
