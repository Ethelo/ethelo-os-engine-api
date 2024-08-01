defmodule EtheloApi.Scenarios.ScenarioStats do
  @moduledoc """
  holds the various statistics calculated
  by the engine and post-solve
  This used to be a database field but is now aa purely virtual schema

  There is no validation because these are only created in by the ScenarioImport process, which
  enforces the uniqueness, presence and correct decision

  """

  # TODO proper moduledoc

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioStats
  alias EtheloApi.Structure.Decision

  embedded_schema do
    belongs_to :decision, Decision
    belongs_to :criteria, Criteria
    belongs_to :issue, OptionCategory
    belongs_to :option, Option
    belongs_to :scenario_set, ScenarioSet
    belongs_to :scenario, Scenario

    field :histogram, {:array, :integer}
    field :advanced_stats, {:array, :integer}
    field :total_votes, :integer
    field :abstain_votes, :integer
    field :negative_votes, :integer
    field :neutral_votes, :integer
    field :positive_votes, :integer

    field :support, :float
    field :approval, :float
    field :dissonance, :float
    field :ethelo, :float
    field :average_weight, :float
    field :default, :boolean

    field :seed_allocation, :integer
    field :vote_allocation, :integer
    field :combined_allocation, :integer
    field :final_allocation, :integer
    field :positive_seed_votes_sq, :integer
    field :positive_seed_votes_sum, :integer
    field :seeds_assigned, :integer

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares and Validates attributes for creating a ScenarioStats record

  decision_id is inline as Decision is not available when stats are created
  """
  def cast_changeset(attrs) do
    %ScenarioStats{}
    |> cast(attrs, [
      :histogram,
      :advanced_stats,
      :total_votes,
      :abstain_votes,
      :negative_votes,
      :neutral_votes,
      :positive_votes,
      :support,
      :approval,
      :dissonance,
      :ethelo,
      :average_weight,
      :default,
      :seed_allocation,
      :vote_allocation,
      :combined_allocation,
      :final_allocation,
      :positive_seed_votes_sum,
      :positive_seed_votes_sq,
      :seeds_assigned
    ])
    |> cast_associations(attrs)
  end

  @doc """
  Prepares and Validates associations for a ScenarioStats record
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :decision_id,
      :criteria_id,
      :issue_id,
      :option_id,
      :scenario_id,
      :scenario_set_id
    ])
  end
end
