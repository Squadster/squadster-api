defmodule Squadster.Schedules.Lesson do
  use Ecto.Schema

  import Ecto.Changeset

  alias Squadster.Repo

  schema "lessons" do
    field :name, :string
    field :teacher, :string
    field :index_number, :integer
    field :note, :string
    belongs_to :timetable, Squadster.Schedules.Timetable

    timestamps()
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :teacher, :index_number, :note, :timetable_id])
    |> validate_required([:name, :index_number, :timetable_id])
    |> foreign_key_constraint(:timetable_id)
  end
end
