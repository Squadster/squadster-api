defmodule Squadster.Domain.FormationsSpec do
  use ESpec.Phoenix, async: true
  use ESpec.Phoenix.Extend, :domain

  import Mockery

  alias Squadster.Formations
  alias Squadster.Formations.{Squad, SquadRequest}
  alias Squadster.Formations.Tasks.NormalizeQueue
  alias Squadster.Formations.Services.NotifySquadChanges

  let :user, do: insert(:user)

  describe "find_squad_by_hash_id/1" do
    context "when squad has link_invitations_enabled set to true" do
      let! :squad, do: insert(:squad, link_invitations_enabled: true)

      it "finds squad by it's hash_id" do
        expect Formations.find_squad_by_hash_id(squad().hash_id)
        |> to(eq squad())
      end
    end

    context "when squad has link_invitations_enabled set to false" do
      let! :squad, do: insert(:squad, link_invitations_enabled: false)

      it "returns nil" do
        expect Formations.find_squad_by_hash_id(squad().hash_id)
        |> to(eq nil)
      end
    end
  end

  describe "find_squad_by_number/1" do
    let! :squad, do: insert(:squad)

    it "finds squad by number" do
      expect Formations.find_squad_by_number(squad().squad_number)
      |> to(eq squad())
    end
  end

  describe "list_squads/0" do
    it "returns list of squads" do
      squads_count = entities_count(Squad)
      expect Formations.list_squads()
      |> Enum.count
      |> to(eq squads_count)
    end
  end

  describe "create_squad/2" do
    let :create_params, do: %{squad_number: "123456", class_day: 3}

    it "returns new squad" do
      {:ok, squad} = Formations.create_squad(create_params(), user())
      expect(squad.__struct__) |> to(eq Squadster.Formations.Squad)
    end
  end

  describe "delete_squad/2" do
    it "deletes a squad by id" do
      %{id: squad_id} = build(:squad) |> with_commander(user()) |> insert
      previous_count = entities_count(Squad)

      Formations.delete_squad(squad_id, user())

      expect entities_count(Squad) |> to(eq previous_count - 1)
    end
  end

  describe "update_squad/2" do
    let :squad, do: build(:squad) |> with_commander(user()) |> insert
    let :update_params, do: %{
      id: squad().id,
      squad_number: "123456",
      advertisment: "~\-o-/~  <  wub-wub-wub",
      class_day: 4,
      link_invitations_enabled: false
    }

    before do
      mock NotifySquadChanges, :call
    end

    it "updates a squad by id" do
      Formations.update_squad(update_params(), user())

      updated_squad = reload(squad())
      expect updated_squad.advertisment |> to(eq update_params().advertisment)
      expect {:ok, updated_squad.class_day} |> to(eq Squad.ClassDayEnum.cast(update_params().class_day))
      expect updated_squad.squad_number |> to(eq update_params().squad_number)
      expect updated_squad.link_invitations_enabled |> to(eq update_params().link_invitations_enabled)
    end
  end

  describe "create_squad_request/2" do
    let :squad, do: insert(:squad)

    it "returns new squad_request" do
      {:ok, squad_request} = Formations.create_squad_request(squad().id, user())
      expect(squad_request.__struct__) |> to(eq Squadster.Formations.SquadRequest)
    end
  end

  describe "delete_squad_request/2" do
    let! squad_request: insert(:squad_request, user: user())

    before do
      mock Notify, :start_link
    end

    context "when user has enough permissions" do
      it "deletes existing squad_request" do
        previous_count = entities_count(SquadRequest)
        Formations.delete_squad_request(squad_request().id, user())
        expect entities_count(SquadRequest) |> to(eq previous_count - 1)
      end

      it "returns deleted squad_request" do
        {:ok, squad_request} = Formations.delete_squad_request(squad_request().id, user())
        expect(squad_request.__struct__) |> to(eq Squadster.Formations.SquadRequest)
      end
    end

    context "when user does not have enough permissions" do
      let stranger: insert(:user)

      it "should not delete existing squad_request" do
        previous_count = entities_count(SquadRequest)
        Formations.delete_squad_request(squad_request().id, stranger())
        expect entities_count(SquadRequest) |> to(eq previous_count)
      end

      it "returns error" do
        {:error, message} = Formations.delete_squad_request(squad_request().id, stranger())

        expect message |> to_not(be nil)
      end
    end
  end

  describe "approve_squad_request/2" do
    let! squad_request: insert(:squad_request, user: insert(:user), squad: squad())
    let squad: build(:squad) |> with_commander(user()) |> insert

    before do
      mock NormalizeQueue, :start_link
      mock Notify, :start_link
    end

    context "when user has enough permissions" do
      it "returns new squad_member" do
        {:ok, squad_member} = Formations.approve_squad_request(squad_request().id, user())
        expect(squad_member.__struct__) |> to(eq Squadster.Formations.SquadMember)
      end
    end

    context "when user does not have enough permissions" do
      let :squad, do: insert(:squad)

      it "returns error" do
        {:error, message} = Formations.approve_squad_request(squad_request().id, user())
        expect message |> to_not(be nil)
      end
    end
  end

  describe "create_squad_member/2" do
    let :squad, do: insert(:squad)

    before do
      mock NormalizeQueue, :start_link
    end

    it "returns new squad_member" do
      {:ok, squad_member} = Formations.create_squad_member(user(), squad())
      expect(squad_member.__struct__) |> to(eq Squadster.Formations.SquadMember)
    end
  end

  describe "update_squad_member/2" do
    let :squad_member, do: insert(:squad_member, user: insert(:user), squad: squad())
    let :squad, do: build(:squad) |> with_commander(user()) |> insert
    let :update_params, do: %{id: squad_member().id, role: "journalist"}

    before do
      mock NormalizeQueue, :start_link
    end

    context "when user has enough permissions" do
      it "updates squad_member" do
        {:ok, squad_member} = Formations.update_squad_member(update_params(), user())
        expect(squad_member.__struct__) |> to(eq Squadster.Formations.SquadMember)
      end
    end

    context "when user does not have enough permissions" do
      let :squad, do: insert(:squad)

      it "returns error" do
        {:error, message} = Formations.update_squad_member(update_params(), user())
        expect message |> to_not(be nil)
      end
    end
  end

  describe "bulk_update_squad_members/2" do
    let! :squad_member, do: insert(:squad_member, user: insert(:user), squad: squad())
    let :squad, do: build(:squad) |> with_commander(user()) |> insert
    let :update_params, do: [%{id: squad_member().id |> Integer.to_string, role: "journalist"}]

    before do
      mock NormalizeQueue, :start_link
    end

    context "when user has enough permissions" do
      it "updates squad_members" do
        {:ok, squad_members} = Formations.bulk_update_squad_members(update_params(), user())
        expect(squad_members[squad_member().id].__struct__) |> to(eq Squadster.Formations.SquadMember)
      end
    end

    context "when user does not have enough permissions" do
      let :squad, do: insert(:squad)
      let :user, do: insert(:user, squad_member: insert(:squad_member))

      it "returns error" do
        {:error, message} = Formations.bulk_update_squad_members(update_params(), user())
        expect message |> to_not(be nil)
      end
    end
  end

  describe "delete_squad_member/2" do
    before do
      mock NormalizeQueue, :start_link
    end

    let :squad_member, do: insert(:squad_member, user: insert(:user), squad: squad())
    let :squad, do: build(:squad) |> with_commander(user()) |> insert

    context "when user has enough permissions" do
      it "deletes squad_member" do
        {:ok, squad_member} = Formations.delete_squad_member(squad_member().id, user())
        expect(squad_member.__struct__) |> to(eq Squadster.Formations.SquadMember)
      end
    end

    context "when user does not have enough permissions" do
      let :squad, do: insert(:squad)

      it "returns error" do
        {:error, message} = Formations.delete_squad_member(squad_member().id, user())
        expect message |> to_not(be nil)
      end
    end
  end
end
