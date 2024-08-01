defmodule EtheloApi.Invocation.Cache do
  @moduledoc """
  Store for cached hashes and invocation jsons
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EtheloApi.Structure.Decision
  alias EtheloApi.Invocation.Cache

  schema "cache" do
    belongs_to(:decision, Decision, on_replace: :raise)

    field(:key, :string)
    field(:value, :string)
    timestamps(type: :utc_datetime)
  end

  def add_validations(%Ecto.Changeset{} = changeset, _decision_id) do
    changeset
    |> unique_constraint(:key, name: :unique_update_decision_cache_key)
  end

  def base_changeset(%Cache{} = cache, %{} = attrs) do
    cache |> cast(attrs, [:key, :value])
  end

  def create_changeset(attrs, %Decision{} = decision) do
    %Cache{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  def update_changeset(%Cache{} = cache, attrs) do
    cache
    |> base_changeset(attrs)
    |> add_validations(cache.decision_id)
  end
end
