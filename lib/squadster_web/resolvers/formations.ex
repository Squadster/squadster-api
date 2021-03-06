defmodule SquadsterWeb.Resolvers.Formations do
  alias Squadster.Formations

  import Mockery.Macro

  def squads(_parent, _args, _resolution) do
    {:ok, Formations.list_squads}
  end

  def squad(_parent, %{squad_number: number}, _resolution) do
    case Formations.find_squad_by_number(number) do
      nil -> {:error, "squad with number #{number} does not exist"}
      squad -> {:ok, squad}
    end
  end

  def create_squad(_parent, args, %{context: %{current_user: user}}) do
    mockable(Formations).create_squad(args, user)
  end

  def create_squad(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def update_squad(_parent, args, %{context: %{current_user: user}}) do
    mockable(Formations).update_squad(args, user)
  end

  def update_squad(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def delete_squad(_parent, %{id: id}, %{context: %{current_user: user}}) do
    mockable(Formations).delete_squad(id, user)
  end

  def delete_squad(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def create_squad_request(_parent, %{squad_id: squad_id}, %{context: %{current_user: user}}) do
    mockable(Formations).create_squad_request(squad_id, user)
  end

  def create_squad_request(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def approve_squad_request(_parent, %{id: id}, %{context: %{current_user: user}}) do
    mockable(Formations).approve_squad_request(id, user)
  end

  def approve_squad_request(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def delete_squad_request(_parent, %{id: id}, %{context: %{current_user: user}}) do
    mockable(Formations).delete_squad_request(id, user)
  end

  def delete_squad_request(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def update_squad_members(_parent, %{batch: args}, %{context: %{current_user: user}}) do
    case mockable(Formations).bulk_update_squad_members(args, user) do
      {:ok, result} -> {:ok, Enum.map(result, fn {_index, element} -> element end)}
      nil -> {:error, "Not enough permissions"}
    end
  end

  def update_squad_members(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def update_squad_member(_parent, args, %{context: %{current_user: user}}) do
    mockable(Formations).update_squad_member(args, user)
  end

  def update_squad_member(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def delete_squad_member(_parent, %{id: id}, %{context: %{current_user: user}}) do
    mockable(Formations).delete_squad_member(id, user)
  end

  def delete_squad_member(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end
end
