defmodule ShelleyPlants.Repo.Migrations.CreateMcpTokens do
  use Ecto.Migration

  def change do
    create table(:mcp_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :token_hash, :binary, null: false
      add :revoked_at, :utc_datetime
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:mcp_tokens, [:token_hash])
    create index(:mcp_tokens, [:user_id])
  end
end
