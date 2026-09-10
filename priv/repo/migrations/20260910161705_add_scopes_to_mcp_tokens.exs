defmodule ShelleyPlants.Repo.Migrations.AddScopesToMcpTokens do
  use Ecto.Migration

  def change do
    alter table(:mcp_tokens) do
      add :scopes, {:array, :string}, null: false, default: ["read"]
    end
  end
end
