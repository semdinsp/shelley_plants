defmodule ShelleyPlantsWeb.Router do
  use ShelleyPlantsWeb, :router

  import ShelleyPlantsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShelleyPlantsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShelleyPlantsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  ## Plant catalog routes
  ## All routes use mount_current_scope so guests can browse.
  ## PlantLive.Form has its own on_mount :require_admin guard.

  scope "/", ShelleyPlantsWeb do
    pipe_through :browser

    live_session :plants,
      on_mount: [{ShelleyPlantsWeb.UserAuth, :mount_current_scope}] do
      live "/plants", PlantLive.Index, :index
      live "/plants/gallery", PlantLive.Gallery, :index
      live "/plants/new", PlantLive.Form, :new
      live "/plants/:id", PlantLive.Show, :show
      live "/plants/:id/edit", PlantLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShelleyPlantsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:shelley_plants, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShelleyPlantsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Admin routes

  scope "/admin", ShelleyPlantsWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    get "/plants/export", Admin.PlantExportController, :export

    live_session :require_admin,
      on_mount: [{ShelleyPlantsWeb.UserAuth, :require_admin}] do
      live "/", Admin.DashboardLive, :index
    end
  end

  ## Authentication routes

  scope "/", ShelleyPlantsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ShelleyPlantsWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/settings", SettingsLive, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ShelleyPlantsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ShelleyPlantsWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
