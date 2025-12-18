defmodule SdbWeb.Cors do
  @moduledoc """
  CORS configuration for the API.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()
    allowed_origins = Application.get_env(:sdb, :allowed_origins, [])

    if origin in allowed_origins do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("access-control-allow-credentials", "true")
      |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "Content-Type, Accept, Authorization")
      |> put_resp_header("access-control-max-age", "86400")
      |> handle_preflight()
    else
      # No CORS headers = browser blocks the request
      handle_preflight(conn)
    end
  end

  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  defp handle_preflight(conn), do: conn
end
