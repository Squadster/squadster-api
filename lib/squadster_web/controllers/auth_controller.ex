defmodule SquadsterWeb.AuthController do
  use SquadsterWeb, :controller

  import Mockery.Macro

  plug Ueberauth when action not in [:destroy]
  plug SquadsterWeb.Plugs.Auth when action in [:destroy]

  alias Squadster.Accounts
  alias Squadster.Formations

  @base_redirect_url Application.fetch_env!(:ueberauth, Ueberauth.Strategy.VK.OAuth)[:base_redirect_url]

  def destroy(conn, _params) do
    Accounts.logout(conn)
    conn
    |> put_status(:ok)
    |> json(%{message: "Logged out"})
  end

  def callback(%{assigns: %{ueberauth_failure: %{errors: [%{message: reason}]}}} = conn, _params) do
    send_auth_error(conn, reason)
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    case mockable(Accounts).find_or_create_user(auth) do
      {:error, reason} -> send_auth_error(conn, reason)
      {status, user} ->
        if mobile?(params["state"]) do
          conn |> render("callback.json", user: user, show_info: show_info?(status))
        else
          warnings = case create_squad_member(params["state"], user) do
            {:ok, _member} -> []
            {:error, message} -> [message]
          end
          conn |> redirect(external: redirect_url(user: user, warnings: warnings, show_info: show_info?(status)))
        end
    end
  end

  defp send_auth_error(conn, reason) do
    redirect(conn, external: redirect_url(error: reason))
  end

  defp redirect_url(error: reason) do
    @base_redirect_url <> URI.encode_query(%{message: "Error", reason: reason})
  end

  defp redirect_url(user: user, warnings: warnings, show_info: show_info) do
    user_data = Map.take(user, Accounts.User.user_fields)
    @base_redirect_url <> URI.encode_query(%{
      message: "Logged in",
      warnings: Poison.encode(warnings) |> elem(1),
      user: Poison.encode(user_data) |> elem(1),
      show_info: show_info
    })
  end

  defp create_squad_member("hash_id=" <> hash_id, user) do
    squad = Formations.find_squad_by_hash_id(hash_id)
    if squad do
      user |> Formations.create_squad_member(squad)
    else
      {:error, "Invalid hash_id"}
    end
  end

  defp create_squad_member(nil, _user),    do: {:ok, nil}
  defp create_squad_member(_state, _user), do: {:error, "Invalid state"}

  defp mobile?("mobile=true"), do: true
  defp mobile?(_state),        do: false

  defp show_info?(:created), do: true
  defp show_info?(:found),   do: false
end
