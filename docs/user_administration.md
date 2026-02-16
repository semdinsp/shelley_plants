# User Administration

## Overview

Users are stored in the `users` table with an `is_admin` boolean flag (default `false`). Admin users have access to the `/admin` routes and are identified via `current_scope.admin?` throughout the app.

## Granting Admin Access

Admin status is managed via the `Accounts.set_user_admin/2` function. There is no UI for this — it is done via IEx console.

### Using IEx

Start an IEx session:

```bash
iex -S mix
# or in production:
iex -S mix phx.server
```

Find the user and grant admin:

```elixir
user = ShelleyPlants.Accounts.get_user_by_email("someone@example.com")
ShelleyPlants.Accounts.set_user_admin(user, true)
```

Revoke admin:

```elixir
user = ShelleyPlants.Accounts.get_user_by_email("someone@example.com")
ShelleyPlants.Accounts.set_user_admin(user, false)
```

### Direct Database (psql)

```sql
UPDATE users SET is_admin = true WHERE email = 'someone@example.com';
UPDATE users SET is_admin = false WHERE email = 'someone@example.com';
```

## How Admin Authorization Works

| Layer | Mechanism | Location |
|-------|-----------|----------|
| Database | `is_admin` boolean column | `users` table |
| Schema | `is_admin` field | `User` schema |
| Session scope | `admin?` boolean | `Scope.for_user/1` |
| LiveView guard | `on_mount(:require_admin, ...)` | `UserAuth` |
| Plug guard | `require_admin_user/2` plug | `UserAuth` |
| Routes | `/admin` scope | `Router` |

## Adding New Admin Routes

Add LiveViews to the existing admin `live_session` block in `router.ex`:

```elixir
scope "/admin", ShelleyPlantsWeb do
  pipe_through [:browser, :require_authenticated_user, :require_admin_user]

  live_session :require_admin,
    on_mount: [{ShelleyPlantsWeb.UserAuth, :require_admin}] do
    live "/plants", Admin.PlantLive.Index, :index
    live "/plants/new", Admin.PlantLive.Index, :new
    live "/plants/:id/edit", Admin.PlantLive.Index, :edit
  end
end
```

## Checking Admin Status in Code

In a LiveView or component, check `current_scope.admin?`:

```elixir
if socket.assigns.current_scope.admin? do
  # admin-only logic
end
```

In a template:

```heex
<%= if @current_scope && @current_scope.admin? do %>
  <.link navigate={~p"/admin"}>Admin</.link>
<% end %>
```
