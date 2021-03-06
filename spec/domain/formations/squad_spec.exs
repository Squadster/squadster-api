defmodule Squadster.Domain.Formations.SquadSpec do
  use ESpec.Phoenix, async: true
  use ESpec.Phoenix.Extend, :domain

  alias Squadster.Formations.Squad

  describe "changeset" do
    context "when params are valid" do
      it "is valid" do
        %{valid?: is_valid} = %{squad_number: "123456", class_day: :monday} |> Squad.changeset
        expect is_valid |> to(be true)
      end

      describe "hash_id case" do
        context "when squad does not have hash_id yet" do
          let :squad, do: insert(:squad, hash_id: nil)

          it "should set hash_id" do
            %{changes: changes} = squad() |> Squad.changeset(%{})
            expect changes
            |> Map.has_key?(:hash_id)
            |> to(be true)
          end
        end

        context "when squad has hash_id" do
          let :squad, do: insert(:squad)

          it "should not update hash_id" do
            %{changes: changes} = squad() |> Squad.changeset(%{})
            expect changes
            |> Map.has_key?(:hash_id)
            |> to(be false)
          end
        end
      end
    end

    context "when params are invalid" do
      context "when squad_member is not set" do
        it "is not valid" do
          %{valid?: is_valid} = %{class_day: :monday} |> Squad.changeset
          expect is_valid |> to(be false)
        end
      end

      context "when class_day is not set" do
        it "is not valid" do
          %{valid?: is_valid} = %{squad_number: "123456"} |> Squad.changeset
          expect is_valid |> to(be false)
        end
      end
    end
  end

  describe "commander/1" do
    let :user, do: insert(:user)
    let! :squad, do: build(:squad) |> with_commander(user()) |> insert

    it "returns commander for given squad" do
      %{squad_member: commander} = user() |> Repo.preload(:squad_member)
      expect squad()
      |> Squad.commander()
      |> to(eq commander)
    end
  end
end
