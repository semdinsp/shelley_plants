# Points plants at the client's updated photos (September 2026).
#
# The old photos are kept in priv/static/images/plants/; the new ones sit
# alongside them with a `_2` suffix. Plants are matched on latin_name, so the
# script is safe to run more than once.
#
# Dev:
#
#     mix run --no-start priv/repo/seeds/update_plant_photos_2026_09.exs
#
# Production (Fly.io) — starts only the Repo, so it won't clash with the
# running server's port:
#
#     fly ssh console -C "/app/bin/shelley_plants eval 'Code.eval_file(Application.app_dir(:shelley_plants, \"priv/repo/seeds/update_plant_photos_2026_09.exs\"))'"

import Ecto.Query

alias ShelleyPlants.Catalog.Plant
alias ShelleyPlants.Repo

photos = %{
  "Agastache foeniculum" => "/images/plants/agastache_foeniculum_2.jpg",
  "Agastache nepetoides" => "/images/plants/agastache_nepetoides_2.jpg",
  "Anaphalis margaritacea" => "/images/plants/anaphalis_margaritacea_2.jpg",
  "Aquilegia canadensis" => "/images/plants/aquilegia_canadensis_2.jpg",
  "Asclepias incarnata" => "/images/plants/asclepias_incarnata_2.jpg",
  "Blephilia ciliata" => "/images/plants/blephilia_ciliata_2.jpg",
  "Coreopsis lanceolata" => "/images/plants/coreopsis_lanceolata_2.jpg",
  "Elymus canadensis" => "/images/plants/elymus_canadensis_2.jpg",
  "Elymus hystrix" => "/images/plants/elymus_hystrix_2.jpg",
  "Eutrochium maculatum" => "/images/plants/eutrochium_maculatum_2.jpg",
  "Geum triflorum" => "/images/plants/geum_triflorum_2.jpg",
  "Liatris aspera" => "/images/plants/liatris_aspera_2.jpg",
  "Lobelia siphilitica" => "/images/plants/lobelia_siphilitica_2.jpg",
  "Monarda fistulosa" => "/images/plants/monarda_fistulosa_2.jpg",
  "Penstemon digitalis" => "/images/plants/penstemon_digitalis_2.jpg",
  "Penstemon hirsutus" => "/images/plants/penstemon_hirsutus_2.jpg",
  "Prunella vulgaris var. lanceolata" => "/images/plants/prunella_vulgaris_var_lanceolata_2.jpg",
  "Ratibida columnifera" => "/images/plants/ratibida_columnifera_2.jpg",
  "Ratibida pinnata" => "/images/plants/ratibida_pinnata_2.jpg",
  "Schizachyrium scoparium" => "/images/plants/schizachyrium_scoparium_2.jpg",
  "Sorghastrum nutans" => "/images/plants/sorghastrum_nutans_2.jpg",
  "Sporobolus heterolepis" => "/images/plants/sporobolus_heterolepis_2.jpg",
  "Symphyotrichum laeve" => "/images/plants/symphyotrichum_laeve_2.jpg",
  "Symphyotrichum novae-angliae" => "/images/plants/symphyotrichum_novae_angliae_2.jpg"
}

Application.load(:shelley_plants)
Application.ensure_all_started(:ssl)

{:ok, _, _} =
  Ecto.Migrator.with_repo(Repo, fn _repo ->
    now = DateTime.utc_now(:second)

    results =
      for {latin_name, picture} <- Enum.sort(photos) do
        {count, _} =
          from(p in Plant, where: p.latin_name == ^latin_name)
          |> Repo.update_all(set: [picture: picture, updated_at: now])

        IO.puts("#{if count == 1, do: "updated", else: "NOT FOUND"}  #{latin_name}")
        count
      end

    IO.puts("\n#{Enum.sum(results)} of #{map_size(photos)} plants updated.")
  end)
