defmodule EtheloApi.Structure.ScenarioConfig do
  use DocsComposer, module: EtheloApi.Structure.Docs.ScenarioConfig

  @moduledoc """
  #{@doc_map.strings.scenario_config}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(@doc_map.examples)}
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Structure.Decision

  schema "scenario_configs" do
    belongs_to :decision, Decision

    field :bins, :integer, default: 5
    field :ci, :decimal, default: Decimal.from_float(0.5)

    field :enabled, :boolean, default: true
    # milliseconds
    field :engine_timeout, :integer, default: 10 * 1000

    field :max_scenarios, :integer, default: 10

    field :normalize_influents, :boolean, default: false
    field :normalize_satisfaction, :boolean, default: true
    field :per_option_satisfaction, :boolean, default: false

    field :preview_engine_hash, :string, default: nil
    field :published_engine_hash, :string, default: nil

    field :quad_cutoff, :integer, default: nil
    field :quad_max_allocation, :integer, default: nil
    field :quad_round_to, :integer, default: nil
    field :quad_seed_percent, :float, default: nil
    field :quad_total_available, :integer, default: nil
    field :quad_user_seeds, :integer, default: nil
    field :quad_vote_percent, :float, default: nil
    field :quadratic, :boolean, default: false

    field :skip_solver, :boolean, default: false
    field :slug, :string
    # 1hr
    field :solve_interval, :integer, default: 60 * 60 * 1000
    field :support_only, :boolean, default: false
    field :tipping_point, :decimal, default: Decimal.from_float(0.33333)
    field :title, :string
    # 1 hour (ttl is in seconds)
    field :ttl, :integer, default: 3600

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%ScenarioConfig{} = scenario_config, attrs) do
    # ensure floats/decimals are parsed
    attrs = attrs |> stringify_value(:tipping_point) |> stringify_value(:ci)

    scenario_config
    |> cast(attrs, [
      :bins,
      :ci,
      :enabled,
      :engine_timeout,
      :max_scenarios,
      :normalize_influents,
      :normalize_satisfaction,
      :per_option_satisfaction,
      :preview_engine_hash,
      :published_engine_hash,
      :quad_cutoff,
      :quad_max_allocation,
      :quad_round_to,
      :quad_seed_percent,
      :quad_total_available,
      :quad_user_seeds,
      :quad_vote_percent,
      :quadratic,
      :skip_solver,
      :slug,
      :solve_interval,
      :support_only,
      :tipping_point,
      :title,
      :ttl
    ])
  end

  @doc """
  Prepares and Validates attributes for creating a ScenarioConfig
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %ScenarioConfig{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating an ScenarioConfig

  Does not allow changing of Decision
  """
  def update_changeset(%ScenarioConfig{} = scenario_config, attrs) do
    scenario_config
    |> Repo.preload(:decision)
    |> base_changeset(attrs)
    |> base_validations()
    |> db_validations(scenario_config.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %ScenarioConfig{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([
      :title,
      :bins,
      :support_only,
      :per_option_satisfaction,
      :normalize_satisfaction,
      :skip_solver,
      :normalize_influents,
      :ttl,
      :engine_timeout,
      :solve_interval,
      :max_scenarios,
      :ci,
      :tipping_point,
      :enabled,
      :quadratic
    ])
    |> validate_has_word(:title)
    |> validate_number(:bins, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_number(:tipping_point, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:ttl, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 * 60 * 24 * 7)
    # at least half a second
    |> validate_number(:engine_timeout, greater_than_or_equal_to: 500)
    |> validate_number(:max_scenarios, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_number(:ci, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> maybe_validate_quadratic
    |> unique_constraint(:slug, name: :unique_scenario_config_slug_index)
  end

  def maybe_validate_quadratic(changeset) do
    case get_field(changeset, :quadratic) do
      nil ->
        changeset

      false ->
        changeset

      true ->
        changeset
        |> validate_required([
          :quad_user_seeds,
          :quad_total_available,
          :quad_cutoff,
          :quad_max_allocation,
          :quad_round_to,
          :quad_seed_percent,
          :quad_vote_percent
        ])
        |> validate_number(:quad_user_seeds, greater_than: 1)
        |> validate_number(:quad_total_available, greater_than: 1)
        |> validate_number(:quad_cutoff, greater_than: 1)
        |> validate_number(:quad_max_allocation, greater_than: 1)
        |> validate_number(:quad_round_to, greater_than: 1)
        |> validate_number(:quad_seed_percent, greater_than: 0)
        |> validate_number(:quad_vote_percent, greater_than: 0)
    end
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, _decision_id) do
    changeset
    |> validate_unique_slug(ScenarioConfig)
    |> update_hash_if_valid
  end

  def update_hash_if_valid(%{valid?: true} = changeset) do
    decision =
      get_field(changeset, :decision) || get_field(changeset, :decision_id)

    {:ok, hash} = EtheloApi.Invocation.generate_scenario_config_hash(decision, changeset.data, false)
    Ecto.Changeset.put_change(changeset, :preview_engine_hash, hash)
  end

  def update_hash_if_valid(changeset), do: changeset

  def export_fields() do
    [
      :bins,
      :ci,
      :enabled,
      :id,
      :engine_timeout,
      :max_scenarios,
      :normalize_influents,
      :normalize_satisfaction,
      :per_option_satisfaction,
      :quad_cutoff,
      :quad_max_allocation,
      :quad_round_to,
      :quad_seed_percent,
      :quad_total_available,
      :quad_user_seeds,
      :quad_vote_percent,
      :quadratic,
      :skip_solver,
      :slug,
      :solve_interval,
      :support_only,
      :tipping_point,
      :title,
      :ttl
    ]
  end
end
