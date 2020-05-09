defmodule Squadster.Formations do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Squadster.Repo
  alias Squadster.Helpers.Permissions
  alias Squadster.Formations.{Squad, SquadMember, SquadRequest}
  alias Squadster.Formations.Services.{CreateSquad, CreateSquadRequest}

  @commander_role 0
  @student_role 3

  def data do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _params), do: queryable

  def list_squads do
    Repo.all(Squad)
  end

  def find_squad(number) do
    Squad |> Repo.get_by(squad_number: number)
  end

  def create_squad(args, user) do
    CreateSquad.call(args, user)
  end

  def update_squad(%{id: id} = args, user) do
    with squad <- Squad |> Repo.get(id) do
      if Permissions.can_update?(user, squad) do
        squad
        |> Squad.changeset(args)
        |> Repo.update
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  def delete_squad(id, user) do
    with squad <- Squad |> Repo.get(id) do
      if Permissions.can_delete?(user, squad) do
        squad |> Repo.delete
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  def create_squad_request(squad_id, user) do
    CreateSquadRequest.call(squad_id, user)
  end

  # TODO
  def approve_squad_request(id, approver) do
    with squad_request <- SquadRequest |> Repo.get(id) do
      if Permissions.can_update?(approver, squad_request) do
        %{squad_member: %{id: approver_id}} = approver |> Repo.preload(:squad_member)
        squad_request
        |> SquadRequest.approve_changeset(%{approver_id: approver_id})
        |> Repo.update

        %{user_id: user_id, squad_id: squad_id} = squad_request
        SquadMember.changeset(%{user_id: user_id, squad_id: squad_id, role: :student})
        |> SquadMember.insert
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  def delete_squad_request(id, user) do
    with squad_request <- SquadRequest |> Repo.get(id) do
      if Permissions.can_delete?(user, squad_request) do
        squad_request |> Repo.delete
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  # TODO
  def bulk_update_squad_members(args, user) do
    ids = Enum.map(args, fn data -> data[:id] end)
    squad_members = all_members(ids)
    if Permissions.can_update?(user, squad_members) do
      Enum.reduce(squad_members, Multi.new(), fn member, batch ->
        data = member_changes(args, member.id)
        batch |> Multi.update(
          member.id,
          member |> SquadMember.changeset(data)
        )
      end)
      |> Repo.transaction
    end
  end

  # TODO
  def update_squad_member(%{id: id} = args, user) do
    with squad_member <- SquadMember |> Repo.get(id) do
      if Permissions.can_update?(user, squad_member) do
        if args[:role] == "commander", do: demote_all_commanders(squad_member)

        SquadMember
        |> Repo.get(id)
        |> SquadMember.changeset(args)
        |> SquadMember.update
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  def delete_squad_member(id, user) do
    with squad_member <- SquadMember |> Repo.get(id) do
      if Permissions.can_delete?(user, squad_member) do
        %{user: %{squad_request: squad_request}} = squad_member |> Repo.preload(user: :squad_request)
        unless is_nil(squad_request), do: squad_request |> Repo.delete
        squad_member |> SquadMember.delete
      else
        {:error, "Not enough permissions"}
      end
    end
  end

  defp all_members(ids) do
    from(
      member in SquadMember,
      where: member.id in ^ids
    )
    |> Repo.all
  end

  defp member_changes(args, id) do
    Enum.find(args, fn arg -> String.to_integer(arg[:id]) == id end)
  end

  defp demote_all_commanders(squad_member) do
    from(
      member in SquadMember,
      where: member.squad_id == ^squad_member.squad_id and member.role == @commander_role,
      update: [set: [role: @student_role]]
    ) |> Repo.update_all([])
  end
end
