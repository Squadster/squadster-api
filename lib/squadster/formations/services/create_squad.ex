defmodule Squadster.Formations.Services.CreateSquad do
  alias Squadster.Repo
  alias Squadster.Formations.{Squad, SquadMember, SquadRequest}

  def call(args, user) do
    user
    |> Repo.preload(:squad_member)
    |> case do
      %{squad_member: nil}     -> create(args, user)
      %{squad_member: _member} -> {:error, "User already has squad"}
    end
  end

  defp create(args, user) do
    args
    |> Squad.changeset
    |> Repo.insert
    |> case do
      {:error, reason} -> {:error, reason}
      {:ok, squad} ->
        squad = squad |> add_commander(user)
        remove_squad_request(user)
        {:ok, squad}
    end
  end

  defp add_commander(%{id: squad_id} = squad, %{id: user_id}) do
    %{role: :commander, user_id: user_id, squad_id: squad_id}
    |> SquadMember.changeset
    |> Repo.insert
    squad
  end

  defp remove_squad_request(user) do
    squad_request = SquadRequest |> Repo.get_by(user_id: user.id)
    unless is_nil(squad_request), do: squad_request |> Repo.delete
  end
end
