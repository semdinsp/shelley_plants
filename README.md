# ShelleyPlants

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# SCOTT CREATION
mix phx.new trackguests2 --binary-id. # need to check on v7
mix phx.gen.auth Accounts User users
mix ecto.migrate

## LOADING PLANTS

### dev
mix plants.import priv/data/plants.json

### prod
copy data
fly sftp put plant_info/plants_import.json /tmp/plants_import.json


Production (Fly.io):
  fly ssh console --pty -C \
    "/app/bin/shelley_plants eval 
  'ShelleyPlants.Release.import_plants([\"/tmp/plants_import.json\"])'"

  The architecture:


## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
# shelley_plants
