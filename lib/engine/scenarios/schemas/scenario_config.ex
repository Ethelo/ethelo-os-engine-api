defmodule Engine.Scenarios.ScenarioConfig do

  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioConfig
  @moduledoc """
  #{@doc_map.strings.scenario_config}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(@doc_map.examples)}
  """

  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias Engine.Scenarios.ScenarioConfig
  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision

  schema "scenario_configs" do
    belongs_to :decision, Decision

    field :title, :string
    field :slug, :string

    field :bins, :integer, default: 5
    field :skip_solver, :boolean, default: false
    field :support_only, :boolean, default: false
    field :per_option_satisfaction, :boolean, default: false
    field :normalize_satisfaction, :boolean, default: true
    field :normalize_influents, :boolean, default: false
    field :override_criteria_weights, :boolean, default: true
    field :override_option_category_weights, :boolean, default: true

    field :max_scenarios, :integer, default: 10
    field :ci, :decimal, default: Decimal.from_float(0.5)
    field :tipping_point, :decimal, default: Decimal.from_float(0.33333)

    field :solve_interval, :integer, default: 60*60*1000 # 1hr
    field :ttl, :integer, default: 3600 # 1 hour (ttl is in sections)
    field :engine_timeout, :integer, default: 10*1000 #milliseconds
    field :enabled, :boolean, default: true
    field :preview_engine_hash, :string, default: nil
    field :published_engine_hash, :string, default: nil

    field :quadratic, :boolean, default: false
    field :quad_user_seeds, :integer, default: nil
    field :quad_total_available, :integer, default: nil
    field :quad_cutoff, :integer, default: nil
    field :quad_max_allocation, :integer, default: nil
    field :quad_round_to, :integer, default: nil
    field :quad_seed_percent, :float, default: nil
    field :quad_vote_percent, :float, default: nil

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([
      :title, :bins, :support_only, :per_option_satisfaction, :normalize_satisfaction, :skip_solver,
      :normalize_influents, :ttl, :engine_timeout, :solve_interval, :max_scenarios, :ci, :tipping_point, :enabled,
      :quadratic,
      ])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_number(:bins, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_number(:tipping_point, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:ttl, greater_than_or_equal_to: 0, less_than_or_equal_to: 60*60*24*7)
    |> validate_number(:engine_timeout, greater_than_or_equal_to: 500) # at least half a second
    |> validate_number(:max_scenarios, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_number(:ci, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> maybe_update_hash
    |> maybe_validate_quadratic
    |> unique_constraint(:slug, name: :unique_scenario_config_slug_index)
  end

  def maybe_validate_quadratic(changeset) do
    case get_field(changeset, :quadratic) do
      nil -> changeset
      false -> changeset
      true ->
        changeset
        |> validate_required([:quad_user_seeds, :quad_total_available, :quad_cutoff, :quad_max_allocation,
        :quad_round_to, :quad_seed_percent, :quad_vote_percent])
        |> validate_number(:quad_user_seeds, greater_than: 1)
        |> validate_number(:quad_total_available, greater_than: 1)
        |> validate_number(:quad_cutoff, greater_than: 1)
        |> validate_number(:quad_max_allocation, greater_than: 1)
        |> validate_number(:quad_round_to, greater_than: 1)
        |> validate_number(:quad_seed_percent, greater_than: 0)
        |> validate_number(:quad_vote_percent, greater_than: 0)

    end
  end


  @doc false
  def base_changeset(%ScenarioConfig{} = scenario_config, attrs) do
    attrs = attrs |> stringify_value(:tipping_point) |> stringify_value(:ci) #ensure floats/decimals are parsed

    scenario_config
    |> cast(attrs, [
      :title, :slug, :bins, :support_only, :per_option_satisfaction, :normalize_satisfaction,
      :normalize_influents, :ttl, :engine_timeout, :solve_interval, :max_scenarios, :ci, :tipping_point, :enabled,
      :skip_solver, :preview_engine_hash, :published_engine_hash,
      :quadratic, :quad_user_seeds, :quad_total_available, :quad_cutoff, :quad_max_allocation,
      :quad_round_to, :quad_seed_percent, :quad_vote_percent,
      ])
  end

  @doc """
  Validates creation of an ScenarioConfig on a Decision.
  """
  def create_changeset(%ScenarioConfig{} = scenario_config, attrs, %Decision{} = decision) do
    scenario_config
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations
  end

  @doc """
  Validates update of an ScenarioConfig.

  Does not allow changing of Decision
  """
  def update_changeset(%ScenarioConfig{} = scenario_config, attrs) do
    scenario_config
    |> Repo.preload(:decision)
    |> base_changeset(attrs)
    |> add_validations
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    ScenarioConfig |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end

  def decision_or_decision_id(changeset) do
    decision = Ecto.Changeset.get_field( changeset, :decision)
    if is_nil(decision) do
      Ecto.Changeset.get_field( changeset, :decision_id)
    else
      decision
    end
  end

  def maybe_update_hash(%{valid?: true } = changeset) do
    decision = decision_or_decision_id(changeset)
    case Engine.Invocation.generate_scenario_config_hash(decision, changeset.data, false) do
      {:ok, hash} -> Ecto.Changeset.put_change(changeset, :preview_engine_hash, hash)
      _ -> changeset
    end
  end
  def maybe_update_hash(changeset), do: changeset

end
