defmodule SdbWeb.Plugs.HandleParseErrors do
  @moduledoc """
  Handles Plug.Parsers.ParseError and returns a 400 Bad Request response.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    try do
      conn
    rescue
      e in Plug.Parsers.ParseError ->
        Logger.warning("Parse error: #{inspect(e)}")

        conn
        |> send_resp(400, Jason.encode!(%{error: "Invalid request body"}))
        |> halt()
    end
  end
end
