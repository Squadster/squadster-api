defmodule Squadster.Domain.Helpers.PermissionsSpec do
  use ESpec.Phoenix, async: true
  use ESpec.Phoenix.Extend, :helper

  import Squadster.Support.Factory

  alias Helpers.Permissions

  let :user do
    member = insert(:squad_member, role: :commander)
    insert(:user, squad_member: member)
  end

  let :squad do
    %{squad_member: %{squad: squad}} = user() |> Repo.preload(squad_member: :squad)
    squad
  end

  let :squad_member do
    %{squad_member: %{squad: squad}} = user() |> Repo.preload(squad_member: :squad)
    insert(:squad_member, squad: squad)
  end

  let :member_of_another_squad do
    insert(:squad_member)
  end

  let :another_squad do
    insert(:squad)
  end

  let :request do
    insert(:squad_request, squad: squad())
  end

  let :request_to_another_squad do
    insert(:squad_request)
  end

  describe "can_update?/2" do
    context "when checking squad" do
      context "if user is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_update?(squad())) |> to(eq true)
        end

        context "and this is not a target squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_update?(squad())) |> to(eq true)
        end

        context "and this is not a target squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_update?(squad())) |> to(eq true)
        end

        context "and this is not a target squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_update?(squad())) |> to(eq false)
        end
      end
    end

    context "when checking squad_request" do
      context "if approver is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_update?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if approver is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_update?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if approver is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_update?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if approver is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_update?(request())) |> to(eq false)
        end
      end
    end

    context "when checking squad_member" do
      context "if user is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_update?(squad_member())) |> to(eq true)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(member_of_another_squad())) |> to(eq false)
          end
        end

        context "and user tries to update himself" do
          let :squad_member do
            insert(:squad_member, user: user())
          end

          it "returns false" do
            expect(user() |> Permissions.can_update?(squad_member())) |> to(eq false)
          end
        end
      end

      context "if user is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_update?(squad_member())) |> to(eq false)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(member_of_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_update?(squad_member())) |> to(eq false)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(member_of_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_update?(squad_member())) |> to(eq false)
        end
      end
    end
  end

  describe "can_delete?/2" do
    context "when checking squad" do
      context "if user is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_delete?(squad())) |> to(eq true)
        end

        context "and this is not a target squad" do
          it "returns false" do
            expect(user() |> Permissions.can_update?(another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad())) |> to(eq false)
        end
      end

      context "if user is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad())) |> to(eq false)
        end
      end

      context "if user is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad())) |> to(eq false)
        end
      end
    end

    context "when checking squad_request" do
      context "if user is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_delete?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_delete?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns true" do
          expect(user() |> Permissions.can_delete?(request())) |> to(eq true)
        end

        context "and this is not a squad of a request" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(request_to_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(request())) |> to(eq false)
        end
      end

      context "when user is a creator of squad_request" do
        let :user do
          insert(:user)
        end

        let :request do
          insert(:squad_request, user: user())
        end

        it "returns true" do
          expect(user() |> Permissions.can_delete?(request())) |> to(eq true)
        end
      end
    end

    context "when checking squad_member" do
      context "if user is a commander of the squad" do
        it "returns true" do
          expect(user() |> Permissions.can_delete?(squad_member())) |> to(eq true)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(member_of_another_squad())) |> to(eq false)
          end
        end

        context "and user tries to delete himself" do
          let :squad_member do
            insert(:squad_member, user: user())
          end

          it "returns true" do
            expect(user() |> Permissions.can_delete?(squad_member())) |> to(eq true)
          end
        end
      end

      context "if user is a deputy_commander of the squad" do
        let :user do
          member = insert(:squad_member, role: :deputy_commander)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad_member())) |> to(eq false)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(member_of_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a journalist of the squad" do
        let :user do
          member = insert(:squad_member, role: :journalist)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad_member())) |> to(eq false)
        end

        context "and this is a member of another squad" do
          it "returns false" do
            expect(user() |> Permissions.can_delete?(member_of_another_squad())) |> to(eq false)
          end
        end
      end

      context "if user is a student" do
        let :user do
          member = insert(:squad_member)
          insert(:user, squad_member: member)
        end

        it "returns false" do
          expect(user() |> Permissions.can_delete?(squad_member())) |> to(eq false)
        end
      end
    end
  end
end
