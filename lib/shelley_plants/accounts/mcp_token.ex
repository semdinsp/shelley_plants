defmodule ShelleyPlants.Accounts.McpToken do
  @moduledoc """
  A named, revocable token used to authenticate MCP clients as a user.

  The raw token is only ever available at creation time. Only its SHA-256
  hash is persisted, so a database read alone cannot be used to authenticate.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ShelleyPlants.Accounts.User

  @hash_algorithm :sha256
  @rand_size 32

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "mcp_tokens" do
    field :name, :string
    field :token_hash, :binary
    field :revoked_at, :utc_datetime
    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Builds a new token for `user`.

  Returns `{raw_token, %McpToken{}}`. `raw_token` is the value to show the
  user (once); the struct carries only the hash and is ready to insert.
  """
  def build(user, name) do
    raw_token = :crypto.strong_rand_bytes(@rand_size) |> Base.url_encode64(padding: false)

    {raw_token,
     %__MODULE__{
       name: name,
       token_hash: hash_token(raw_token),
       user_id: user.id
     }}
  end

  def changeset(mcp_token, attrs) do
    mcp_token
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
  end

  @doc """
  Returns the query for looking up an active (non-revoked) token by its raw value.
  """
  def by_raw_token_query(raw_token) do
    from t in __MODULE__,
      where: t.token_hash == ^hash_token(raw_token) and is_nil(t.revoked_at)
  end

  defp hash_token(raw_token) do
    case Base.url_decode64(raw_token, padding: false) do
      {:ok, decoded} -> :crypto.hash(@hash_algorithm, decoded)
      :error -> :crypto.hash(@hash_algorithm, raw_token)
    end
  end
end
