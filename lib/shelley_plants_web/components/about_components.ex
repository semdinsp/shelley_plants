defmodule ShelleyPlantsWeb.AboutComponents do
  @moduledoc false
  use Phoenix.Component

  alias ShelleyPlantsWeb.CoreComponents

  attr :variant, :atom, default: :home, values: [:home, :full]

  def shelley_bio(assigns) do
    ~H"""
    <div>
      <p class="text-xs font-semibold uppercase tracking-[0.2em] text-primary mb-4">
        Founder &amp; Owner
      </p>
      <h2 class="text-3xl font-bold tracking-tight mb-6 sm:text-4xl">Dr. Shelley Ball</h2>
      <p class="text-base font-medium text-base-content/70 mb-6 italic">
        Biologist. Educator. Storyteller.<br />Passionate advocate for the natural world.
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
          and population genetics of insects and was one of the pioneers of DNA
          Barcoding — a DNA-based tool now used globally to inventory the diversity of
          life on Earth. With nearly 30 years of teaching experience spanning
          kindergarten through graduate school, she brings a rare breadth to every
          educational encounter.
        </p>
        <p :if={@variant == :full}>
          Whether she is guiding a youth expedition through a wilderness landscape,
          speaking on stage, or crouching in a meadow to identify a wildflower, Shelley
          brings the same infectious passion - a lifelong and deep love of nature and an
          unwavering belief that connecting to nature is the first step toward
          protecting it.
        </p>
        <p :if={@variant == :full}>
          Shelley opened Biosphere Native Plants, her Ontario Native Plant nursery, in
          May of 2025. Her love of native plants began during her childhood. As a kid
          at the family cottage on Buck Lake, near Westport, ON, Shelley spent much of
          her free time hiking the forests around the lake, with a pocket knife and a
          plant identification guide in hand. No maps. No compass. Just a sense of
          adventure, an unquenchable curiosity, and a desire to learn about the natural
          world around her. All through her childhood, Shelley wanted to become a
          biologist, but learning challenges put that at risk. Through a lot of hard
          work and adapting, Shelley earned her Honours B.Sc. (with High Honours) from
          Carleton University, a Masters of Science from University of Toronto, and a
          Ph.D. from the University of Missouri (Columbia, MO). She has had post
          doctoral positions at the University of Guelph (DNA barcoding) and the
          Bio-protection Research Centre in Canterbury, New Zealand (DNA-based
          identification of pest and exotic insects). In 2009, Shelley returned to
          Canada and joined the federal public service, working as a Senior
          Environmental Assessment Officer for Natural Resources Canada. She recently
          retired from NRCan after nearly 17 years of service.
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
        subtitle="Evolutionary Ecology & Population Genetics"
      />
      <.credential
        icon_path="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064"
        title="Antarctic Expedition"
        subtitle="Homeward Bound Women in Science, 2016"
        href="https://www.1millionwomen.com.au/blog/meet-three-inspiring-women-leading-fight-environment/"
      />
      <.credential
        icon_path="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
        title="TEDx Speaker"
        subtitle="Ottawa TEDx Conference"
        href="https://www.youtube.com/watch?v=rd6ZfzF9wTE"
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
        href="https://www.facebook.com/photo.php?fbid=635316863480442&set=a.615171240711766&id=100066566875144"
      />
      <.credential
        icon_path="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"
        title="Royal Canadian Geographical Society"
        subtitle="Fellow"
        href="https://canadiangeographic.ca/author/shelley-ball/"
      />
      <.credential
        icon_path="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23-.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5"
        title="DNA Barcoding Pioneer"
        subtitle="20 years of DNA barcoding technology"
        href="https://news.uoguelph.ca/2023/02/20-years-of-dna-barcoding-u-of-g-developed-technology-hits-milestone/"
      />
      <.credential
        icon_path="M12 21a9 9 0 100-18 9 9 0 000 18zm0 0c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m-9 9h18"
        title="CFUW UN Representative"
        subtitle="Commission on the Status of Women"
        href="https://www.facebook.com/groups/2232370205/posts/10161646683730206/"
      />
      <.credential
        icon_path="M15.75 10.5l4.72-4.72a.75.75 0 011.28.53v11.38a.75.75 0 01-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 002.25-2.25v-9a2.25 2.25 0 00-2.25-2.25h-9A2.25 2.25 0 002.25 7.5v9a2.25 2.25 0 002.25 2.25z"
        title="Shift Happens"
        subtitle="Co-creator, award-winning environmental field series"
        href="http://www.biosphere-ed.org/shift-happens"
      />
    </div>
    """
  end

  attr :icon_path, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :href, :string, default: nil

  defp credential(assigns) do
    ~H"""
    <.link
      href={@href}
      target={@href && "_blank"}
      rel={@href && "noopener noreferrer"}
      class={[
        "flex items-start gap-3 p-4 rounded-xl bg-base-100 border border-base-200",
        @href && "hover:border-primary/40 transition-colors"
      ]}
    >
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
    </.link>
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
