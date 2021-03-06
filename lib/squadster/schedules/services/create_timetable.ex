defmodule Squadster.Schedules.Services.CreateTimetable do
  alias Squadster.Repo
  alias Squadster.Schedules.Timetable

  def call(args) do
    args
    |> Timetable.changeset
    |> Repo.insert
  end
end
