defmodule Engine.Invocation.Cache do
  use Ecto.Schema
  import Ecto.Changeset
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Decision
  alias Engine.Invocation.Cache

  schema "cache" do
    belongs_to(:decision, Decision, on_replace: :raise)

    field(:key, :string)
    field(:value, :string)
    timestamps()
  end

  def add_validations(%Ecto.Changeset{} = changeset, _decision) do
    changeset
    |> unique_constraint(:key, name: :unique_update_decision_cache_key)
  end

  def base_changeset(%Cache{} = cache, %{} = attrs) do
    cache |> cast(attrs, [:key, :value])
  end

  def create_changeset(%Cache{} = cache, attrs, %Decision{} = decision) do
    cache
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  def update_changeset(%Cache{} = cache, attrs) do
    cache
    |> base_changeset(attrs)
    |> add_validations(cache.decision)
  end
end
