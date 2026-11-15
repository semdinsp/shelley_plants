defmodule ShelleyPlantsWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs. Error pages render with `layout: false`, so each
  page is a complete, self-contained document. They deliberately avoid
  anything that depends on the session or current scope, since errors can
  occur before those plugs have run.
  """
  use ShelleyPlantsWeb, :html

  embed_templates "error_html/*"

  # Fallback for any other status (e.g. 403, 422): plain status message.
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  attr :title, :string, required: true
  attr :code, :string, required: true
  slot :inner_block, required: true

  def error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex" />
        <title>{@title} · Biosphere Native Plants</title>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <meta name="theme-color" content="#2d6a4f" />
        <link rel="stylesheet" href={~p"/assets/css/app.css"} />
        <%!-- Apply the visitor's saved light/dark choice (set by the site's theme toggle) --%>
        <script>
          try {
            const t = localStorage.getItem("phx:theme");
            if (t && t !== "system") document.documentElement.setAttribute("data-theme", t);
          } catch (_) {}
        </script>
      </head>
      <body class="min-h-screen bg-base-100 text-base-content">
        <header class="border-b border-base-200/60 px-4 sm:px-6 lg:px-8">
          <div class="mx-auto flex h-14 max-w-5xl items-center">
            <a href="/" class="flex items-center gap-2" aria-label="Biosphere Native Plants home">
              <img src="/images/biologo.jpg" alt="" class="size-8 rounded-full object-cover" />
              <span class="font-semibold">Biosphere Native Plants</span>
            </a>
          </div>
        </header>
        <main class="px-4 py-16 sm:py-24">
          <div class="mx-auto max-w-xl text-center">
            <p class="text-sm font-semibold tracking-widest text-primary">{@code}</p>
            <h1 class="mt-2 text-3xl font-bold sm:text-4xl">{@title}</h1>
            <div class="mt-4 text-base-content/70">{render_slot(@inner_block)}</div>
            <%!-- Stacked full-width on phones so no button is orphaned on its own row --%>
            <div class="mx-auto mt-8 flex max-w-xs flex-col gap-3 sm:max-w-none sm:flex-row sm:justify-center">
              <a href="/" class="btn btn-primary gap-2">
                <.icon name="hero-home" class="size-5" /> Back to home
              </a>
              <a href="/plants/gallery" class="btn btn-outline gap-2">
                <.icon name="hero-photo" class="size-5" /> Shop plants
              </a>
              <a href="/contact" class="btn btn-outline gap-2">
                <.icon name="hero-envelope" class="size-5" /> Contact us
              </a>
            </div>
          </div>
        </main>
      </body>
    </html>
    """
  end
end
