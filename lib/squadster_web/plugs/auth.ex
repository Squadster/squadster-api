defmodule SquadsterWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller

  alias Squadster.User

  def init(opts), do: opts

  def call(conn, _opts) do
    unless token = Enum.at(get_req_header(conn, "auth-token"), 0) do
      send_auth_error(conn, "Auth token not provided")
    end

    if current_user = User.find_by_token(token) do
      assign(conn, :current_user, current_user)
    else
      send_auth_error(conn, "Auth token is invalid")
    end
  end

  defp send_auth_error(conn, reason) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: reason, message: "Failed to authenticate"})
    |> halt()
  end
end
