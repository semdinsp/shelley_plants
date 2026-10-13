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


## Public MCP endpoint (for AI agents)

`https://biosphere-native-plants.ca/mcp/public` is a public, read-only MCP
server (Streamable HTTP, no authentication) that lets AI agents search the
plant catalogue. It only returns what the public plant pages show, and is
rate limited to 60 requests per minute per IP.

Tools:

- `search_plants`: filter by name, category, light, moisture, height, bloom
  season, flower colour, deer resistance, wildlife (e.g. hummingbirds) and
  Ontario-native status (up to 25 results)
- `get_plant`: full details for one plant, by slug or Latin name
- `list_filters`: valid values for each filter
- `recommend_plants`: plants for a garden's light, moisture, height and
  wildlife goal (uses the garden planner's matching)

To connect from Claude (claude.ai or the desktop app): **Settings ›
Connectors › Add custom connector**, name it "Biosphere Native Plants" and
enter the URL `https://biosphere-native-plants.ca/mcp/public`. No
authentication settings are needed.

From Claude Code:

```bash
claude mcp add --transport http biosphere-plants https://biosphere-native-plants.ca/mcp/public
```

The separate admin endpoint at `/mcp` (with read/write tools) still requires
a bearer token created on the Settings page.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
# shelley_plants
