defmodule ShelleyPlants.Outreach.ContactMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "contact_messages" do
    field :name, :string
    field :email, :string
    field :message, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_message, attrs) do
    contact_message
    |> cast(attrs, [:name, :email, :message])
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &String.trim/1)
    |> update_change(:message, &String.trim/1)
    |> validate_required([:name, :email, :message])
    |> validate_length(:name, max: 120)
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+\.[^@,;\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:message, max: 5000)
  end
end
