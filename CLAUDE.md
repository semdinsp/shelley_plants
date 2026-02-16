# ShelleyPlants - Claude Code Configuration

## Project Overview
Elixir/Phoenix LiveView application using PostgreSQL.

## Tech Stack
- **Elixir** ~> 1.15
- **Phoenix** ~> 1.8.3
- **Phoenix LiveView** ~> 1.1.0
- **Ecto** + PostgreSQL
- **Tailwind CSS** + esbuild
- **Bandit** web server
- **Swoosh** (email), **Req** (HTTP client), **bcrypt** (auth)

## Common Commands

### Setup
```bash
mix setup          # Install deps, create/migrate DB, build assets
mix ecto.reset     # Drop and recreate database
```

### Development
```bash
mix phx.server     # Start development server (localhost:4000)
iex -S mix phx.server  # Start with interactive shell
```

### Testing
```bash
mix test           # Run tests (auto creates/migrates test DB)
mix precommit      # compile --warnings-as-errors, format, test (use before committing)
```

### Database
```bash
mix ecto.migrate   # Run migrations
mix ecto.rollback  # Rollback last migration
mix ecto.gen.migration <name>  # Generate new migration
```

### Assets
```bash
mix assets.build   # Build CSS and JS
mix assets.deploy  # Build minified assets for production
```

### Code Generation
```bash
mix phx.gen.live <context> <schema> <table> <fields...>  # Generate LiveView CRUD
mix phx.gen.context <context> <schema> <table> <fields...>  # Generate context only
mix phx.gen.schema <schema> <table> <fields...>  # Generate schema only
```

## Project Structure
```
lib/
  shelley_plants/        # Business logic (contexts, schemas)
  shelley_plants_web/    # Web layer (controllers, live views, components)
  shelley_plants.ex      # Main application module
  shelley_plants_web.ex  # Web module (imports/macros)
priv/
  repo/migrations/       # Database migrations
  repo/seeds.exs         # Seed data
assets/                  # Frontend assets (JS, CSS)
```

## Code Style
- Run `mix format` before committing
- `mix precommit` runs compile (warnings as errors), format, and tests
- Warnings are treated as errors in compilation
