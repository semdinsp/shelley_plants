defmodule ShelleyPlantsWeb.AboutComponents do
  @moduledoc false
  use Phoenix.Component

  alias ShelleyPlantsWeb.CoreComponents

  attr :variant, :atom, default: :home, values: [:home, :full]

  def shelley_bio(assigns) do
    ~H"""
    <div>
      <p class="text-xs font-semibold uppercase tracking-[0.2em] text-primary mb-4">
        Meet your guide
      </p>
      <h2 class="text-3xl font-bold tracking-tight mb-6 sm:text-4xl">Dr. Shelley Ball</h2>
      <p class="text-base font-medium text-base-content/70 mb-6 italic">
        Biologist. Educator. Storyteller.<br />Advocate for the natural world.
      </p>

      <div class="space-y-4 text-sm text-base-content/70 leading-relaxed">
        <p>
          Dr. Shelley Ball has spent a career building bridges between people and the
          natural world. As the founder of Biosphere Environmental Education, her mission
          is simple and enduring: to connect people to nature, and to inspire them to
          care about it and protect it.
        </p>
        <p :if={@variant == :full}>
          Shelley holds a Ph.D. in Biology with a specialization in evolutionary ecology
          and population genetics, and was among the pioneers of DNA Barcoding — a
          DNA-based tool now used globally to inventory the diversity of life on Earth.
          With nearly 30 years of teaching experience spanning kindergarten through
          graduate school, she brings rare breadth to every educational encounter.
        </p>
        <p :if={@variant == :full}>
          Whether she is guiding an expedition through a wilderness landscape, speaking
          on a conference stage, or crouching in a meadow to identify a wildflower,
          Shelley brings the same infectious passion: a deep love of nature and an
          unwavering belief that understanding it is the first step toward protecting it.
        </p>
      </div>

      <div :if={@variant == :home} class="mt-6">
        <a href="/about" class="btn btn-outline btn-sm gap-2">
          <CoreComponents.icon name="hero-arrow-right" class="size-4" /> Read more about Shelley
        </a>
      </div>
    </div>
    """
  end

  def credentials_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 content-start">
      <.credential
        icon_path="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
        title="Ph.D. in Biology"
        subtitle="Evolutionary Ecology &amp; Population Genetics"
      />
      <.credential
        icon_path="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064"
        title="Antarctic Expedition"
        subtitle="Homeward Bound Women in Science, 2016"
      />
      <.credential
        icon_path="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
        title="TEDx Speaker"
        subtitle="Ottawa TEDx Conference"
      />
      <.credential
        icon_path="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
        title="~30 Years of Teaching"
        subtitle="Kindergarten through graduate school"
      />
      <.credential
        icon_path="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
        title="CFUW Mentoring Award"
        subtitle="National winner, 2018"
      />
      <.credential
        icon_path="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"
        title="Royal Canadian Geographical Society"
        subtitle="Fellow"
      />
    </div>
    """
  end

  attr :icon_path, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true

  defp credential(assigns) do
    ~H"""
    <div class="flex items-start gap-3 p-4 rounded-xl bg-base-100 border border-base-200">
      <div class="shrink-0 mt-0.5 size-8 flex items-center justify-center rounded-lg bg-primary/10">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-4 text-primary"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="1.5"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d={@icon_path} />
        </svg>
      </div>
      <div>
        <p class="font-semibold text-sm">{@title}</p>
        <p class="text-xs text-base-content/50 mt-0.5">{@subtitle}</p>
      </div>
    </div>
    """
  end

  def visit_us(assigns) do
    ~H"""
    <div>
      <p class="text-xs font-semibold uppercase tracking-[0.2em] text-primary mb-4">
        Visit us
      </p>
      <h2 class="text-3xl font-bold tracking-tight mb-6 sm:text-4xl">Find Us</h2>

      <div class="space-y-4 text-sm text-base-content/70 mb-6">
        <div class="flex items-start gap-3">
          <CoreComponents.icon name="hero-map-pin" class="size-5 text-primary mt-0.5 shrink-0" />
          <div>
            <p class="font-medium text-base-content">1107 Althorpe Road</p>
            <p>Westport, ON, K0G 1X0</p>
            <p class="text-xs text-base-content/50 mt-1">(15 min south of Perth)</p>
          </div>
        </div>
        <div class="flex items-start gap-3">
          <CoreComponents.icon name="hero-phone" class="size-5 text-primary mt-0.5 shrink-0" />
          <a href="tel:+16136176524" class="font-medium text-base-content hover:text-primary">
            613-617-6524
          </a>
        </div>
      </div>

      <div class="rounded-xl overflow-hidden border border-base-200 aspect-video">
        <iframe
          title="Map to 1107 Althorpe Road, Westport, ON"
          width="100%"
          height="100%"
          style="border:0"
          loading="lazy"
          referrerpolicy="no-referrer-when-downgrade"
          src="https://maps.google.com/maps?q=1107+Althorpe+Road,+Westport,+ON,+K0G+1X0&output=embed"
        >
        </iframe>
      </div>
    </div>
    """
  end
end
