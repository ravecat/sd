defmodule SdbWeb.Plugs.EnsureUserId do
  @moduledoc """
  Ensures that each request has a user_id assigned.
  Generates a UUID if not present in session and stores it in conn.assigns.user_id.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        user_id = Ecto.UUID.generate()

        conn
        |> put_session(:user_id, user_id)
        |> assign(:user_id, user_id)

      user_id ->
        assign(conn, :user_id, user_id)
    end
  end
end
