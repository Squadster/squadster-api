defmodule Squadster.Domain.FormationsSpec do
  use ESpec.Phoenix, async: true
  use ESpec.Phoenix.Extend, :model

  alias Squadster.Formations
  alias Squadster.Formations.{Squad, SquadRequest}

  let :user, do: insert(:user)

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

    it "creates a new squad with valid attributes" do
      previous_count = entities_count(Squad)

      Formations.create_squad(create_params(), user())

      expect entities_count(Squad) |> to(eq previous_count + 1)
    end

    it "sets creator as a commander" do
      Formations.create_squad(create_params(), user())

      %{squad_member: member} = user() |> Repo.preload(:squad_member)

      expect(Squad |> last |> Squad.commander) |> to(eq member)
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
      class_day: 4
    }

    it "updates a squad by id" do
      Formations.update_squad(update_params(), user())

      expect Repo.get(Squad, squad().id).advertisment |> to(eq update_params().advertisment)
      expect {:ok, Repo.get(Squad, squad().id).class_day} |> to(eq Squad.ClassDayEnum.cast(update_params().class_day))
      expect Repo.get(Squad, squad().id).squad_number |> to(eq update_params().squad_number)
    end
  end

  describe "create_squad_request/2" do
    let :squad, do: insert(:squad)

    it "creates a new squad_request" do
      previous_count = entities_count(SquadRequest)
      Formations.create_squad_request(squad().id, user())
      expect entities_count(SquadRequest) |> to(eq previous_count + 1)
    end

    context "when user has another request" do
      it "should delete old request and create new one" do
        count = entities_count(SquadRequest)
        {:ok, %{id: id}} = Formations.create_squad_request(squad().id, user())

        expect entities_count(SquadRequest) |> to(eq count + 1)

        count = entities_count(SquadRequest)
        {:ok, %{id: new_id}} = Formations.create_squad_request(squad().id, user())

        expect entities_count(SquadRequest) |> to(eq count)
        expect new_id |> to_not(eq id)
      end
    end

    context "when user has a squad" do
      before do
        insert(:squad_member, user: user(), squad: squad())
      end

      it "should not create request" do
        initial_count = entities_count(SquadRequest)

        Formations.create_squad_request(squad().id, user())

        expect entities_count(SquadRequest) |> to(eq initial_count)
      end

      it "should return error with message" do
        {:error, message} = Formations.create_squad_request(squad().id, user())
        expect message |> to_not(be_nil())
      end
    end

    context "delete_squad_request/2" do
      let! :squad_request, do: insert(:squad_request, user: user())

      it "deletes existing squad_request" do
        previous_count = entities_count(SquadRequest)
        Formations.delete_squad_request(squad_request().id, user())
        expect entities_count(SquadRequest) |> to(eq previous_count - 1)
      end
    end

    context "approve_squad_request/2" do
      let! :squad_request, do: insert(:squad_request, user: insert(:user), squad: squad())
      let :squad, do: build(:squad) |> with_commander(user()) |> insert

      it "approves existing squad_request and sets approved_at and approver" do
        expect squad_request().approver |> to(eq nil)
        expect squad_request().approved_at |> to(eq nil)

        Formations.approve_squad_request(squad_request().id, user())

        request = SquadRequest |> Repo.get(squad_request().id) |> Repo.preload(:approver)
        %{squad_member: approver} = user() |> Repo.preload(:squad_member)

        expect request.approver |> to(eq approver)
        expect request.approved_at |> to_not(eq nil)
      end

      it "creates new squad_member" do
        %{user: %{squad_member: squad_member}} = squad_request() |> Repo.preload(user: :squad_member)
        expect squad_member |> to(eq nil)

        Formations.approve_squad_request(squad_request().id, user())

        %{user: %{squad_member: squad_member}} = squad_request() |> Repo.preload(user: :squad_member)
        %{squad_id: squad_id} = squad_member

        expect squad_member |> to_not(eq nil)
        expect squad_id |> to(eq squad().id)
      end
    end
  end
end