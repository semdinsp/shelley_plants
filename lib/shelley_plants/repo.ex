defmodule ShelleyPlants.Repo do
  use Ecto.Repo,
    otp_app: :shelley_plants,
    adapter: Ecto.Adapters.Postgres
end
