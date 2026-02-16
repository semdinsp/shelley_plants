defmodule ShelleyPlants.Catalog do
  @moduledoc """
  The Catalog context.

  Plants are a global catalog. All users (including unauthenticated) may read
  plant data. Only admin users may create, update, or delete plants.
  """

  import Ecto.Query, warn: false
  alias ShelleyPlants.Repo

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlants.Accounts.Scope

  @pubsub_topic "plants"

  @doc """
  Subscribes to notifications about any plant changes.

  The broadcasted messages match the pattern:

    * {:created, %Plant{}}
    * {:updated, %Plant{}}
    * {:deleted, %Plant{}}

  """
  def subscribe_plants do
    Phoenix.PubSub.subscribe(ShelleyPlants.PubSub, @pubsub_topic)
  end

  defp broadcast_plant(message) do
    Phoenix.PubSub.broadcast(ShelleyPlants.PubSub, @pubsub_topic, message)
  end

  @doc """
  Returns the list of all plants, ordered by common name.
  """
  def list_plants do
    Repo.all(from p in Plant, order_by: [asc: p.common_name])
  end

  @doc """
  Gets a single plant.

  Raises `Ecto.NoResultsError` if the Plant does not exist.
  """
  def get_plant!(id), do: Repo.get!(Plant, id)

  @doc """
  Creates a plant. Requires an admin scope.
  """
  def create_plant(%Scope{admin?: true} = _scope, attrs) do
    with {:ok, plant = %Plant{}} <-
           %Plant{}
           |> Plant.changeset(attrs)
           |> Repo.insert() do
      broadcast_plant({:created, plant})
      {:ok, plant}
    end
  end

  @doc """
  Updates a plant. Requires an admin scope.
  """
  def update_plant(%Scope{admin?: true} = _scope, %Plant{} = plant, attrs) do
    with {:ok, plant = %Plant{}} <-
           plant
           |> Plant.changeset(attrs)
           |> Repo.update() do
      broadcast_plant({:updated, plant})
      {:ok, plant}
    end
  end

  @doc """
  Deletes a plant. Requires an admin scope.
  """
  def delete_plant(%Scope{admin?: true} = _scope, %Plant{} = plant) do
    with {:ok, plant = %Plant{}} <- Repo.delete(plant) do
      broadcast_plant({:deleted, plant})
      {:ok, plant}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plant changes.
  """
  def change_plant(%Plant{} = plant, attrs \\ %{}) do
    Plant.changeset(plant, attrs)
  end
end
