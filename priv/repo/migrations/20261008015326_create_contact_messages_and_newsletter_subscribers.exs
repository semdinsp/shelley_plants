defmodule ShelleyPlants.Repo.Migrations.CreateContactMessagesAndNewsletterSubscribers do
  use Ecto.Migration

  def change do
    create table(:contact_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :citext, null: false
      add :message, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:contact_messages, [:inserted_at])

    create table(:newsletter_subscribers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email, :citext, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:newsletter_subscribers, [:email])
  end
end
