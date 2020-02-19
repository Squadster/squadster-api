alias Squadster.Repo

alias Squadster.Accounts.User
alias Squadster.Formations.Squad
alias Squadster.Formations.SquadMember

seeds_config = [users: 30, squads: 2, users_per_squad: 15]

for _ <- (1..seeds_config[:users]) do
  uid = Faker.Util.format("%9d")
  Repo.insert!(%User{
    first_name: Faker.Name.first_name,
    last_name: Faker.Name.last_name,
    birth_date: Faker.Date.date_of_birth(17..20),
    mobile_phone: "+375" <> Faker.Util.format("%9d"),
    university: "University of " <> Faker.Industry.sector,
    faculty: "Faculty of " <> Faker.Industry.sub_sector,
    uid: uid,
    auth_token: Faker.String.base64(85),
    small_image_url: Faker.Avatar.image_url,
    image_url: Faker.Avatar.image_url,
    vk_url: "https://vk.com/id" <> uid
  })
end

for _ <- (1..seeds_config[:squads]) do
  Repo.insert!(%Squad{
    squad_number: Faker.Util.format("%6d"),
    advertisment: Faker.StarWars.quote,
    class_day: Faker.Util.pick([:monday, :twesday, :wednesday, :thursday, :friday, :saturday])
  })
end

for index <- (1..seeds_config[:squads]) do
  squad = Repo.get(Squad, index)

  Repo.all(User)
  |> Enum.slice((index - 1) * seeds_config[:users_per_squad], seeds_config[:users_per_squad])
  |> Enum.each fn user ->
    Repo.insert!(%SquadMember{
      role: :student,
      user: user,
      squad: squad
    })
  end
end
