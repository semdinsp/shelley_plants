defmodule ShelleyPlants.Repo.Migrations.AddSlugToPlants do
  use Ecto.Migration

  import Ecto.Query

  # Adds plants.slug (e.g. "aquilegia-canadensis") for /plants/:slug URLs and
  # backfills it from latin_name. The slug rule is copied here rather than
  # calling ShelleyPlants.Catalog.Plant, so this migration keeps working if
  # the app code changes later. It must match Plant.slugify/1.

  def up do
    alter table(:plants) do
      add :slug, :string
    end

    flush()

    from(p in "plants", select: {p.id, p.latin_name})
    |> repo().all()
    |> Enum.each(fn {id, latin_name} ->
      from(p in "plants", where: p.id == ^id)
      |> repo().update_all(set: [slug: slugify(latin_name)])
    end)

    alter table(:plants) do
      modify :slug, :string, null: false
    end

    create unique_index(:plants, [:slug])
  end

  def down do
    drop index(:plants, [:slug])

    alter table(:plants) do
      remove :slug
    end
  end

  defp slugify(latin_name) do
    latin_name
    |> String.replace(~r/\(.*?\)/, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
