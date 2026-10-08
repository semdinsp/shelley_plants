defmodule ShelleyPlants.Outreach.NewsletterSubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "newsletter_subscribers" do
    field :name, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscriber, attrs) do
    subscriber
    |> cast(attrs, [:name, :email])
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &String.trim/1)
    |> validate_required([:email])
    |> validate_length(:name, max: 120)
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+\.[^@,;\s]+$/,
      message: "must be a valid email address"
    )
    |> unique_constraint(:email)
  end
end
