defmodule Squadster.Repo.Migrations.AddHashIdToSquads do
  use Ecto.Migration

  def change do
    alter table(:squads) do
      add :hash_id, :string
    end
  end
end
