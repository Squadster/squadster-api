defmodule Squadster.Workers.NotifyDuties do
  use Task

  import Ecto.Query
  import SquadsterWeb.Gettext
  import Mockery.Macro

  alias Squadster.Repo
  alias Squadster.Formations.Squad
  alias Squadster.Helpers.Dates

  def start_link do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    tomorrow = Dates.tomorrow |> Date.day_of_week
    from(squad in Squad, where: squad.class_day == ^tomorrow)
    |> Repo.all
    |> Repo.preload(members: :user)
    |> Enum.each(fn %{members: members} ->
      members
      |> Enum.filter(fn member -> member.queue_number == 1 end)
      |> Enum.each(&notify/1)
    end)
  end

  defp notify(%{user: user}) do
    mockable(Squadster.Accounts.Tasks.Notify).start_link([
      message: gettext("You are on duty tomorrow!"),
      target: user
    ])
  end
end
