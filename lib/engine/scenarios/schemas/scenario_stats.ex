defmodule Engine.Scenarios.ScenarioStats do

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioStats
  alias EtheloApi.Structure.Decision

  schema "scenario_stats" do
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

    belongs_to :scenario_set, ScenarioSet
    belongs_to :scenario, Scenario
    belongs_to :criteria, Criteria
    belongs_to :option, Option
    belongs_to :issue, OptionCategory
    belongs_to :decision, Decision

    timestamps()
  end

  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:default])
  end

  def base_changeset(%ScenarioStats{} = scenario_stats, attrs) do
    scenario_stats
    |> cast(attrs, [:histogram, :advanced_stats, :total_votes, :abstain_votes, :negative_votes, :neutral_votes, :positive_votes,
                    :support, :approval, :dissonance, :ethelo, :average_weight, :default, :decision_id,
                    :scenario_set_id, :scenario_id, :criteria_id, :option_id, :issue_id,
                    :seed_allocation, :vote_allocation, :combined_allocation, :final_allocation,
                    :positive_seed_votes_sum, :positive_seed_votes_sq, :seeds_assigned,
                    ])
    |> unique_constraint(:option_id, name: :scenario_stats_default_unique_options)
    |> unique_constraint(:option_id, name: :scenario_stats_solution_unique_options)
    |> unique_constraint(:criteria_id, name: :scenario_stats_default_unique_criteria)
    |> unique_constraint(:criteria_id, name: :scenario_stats_solution_unique_criteria)
    |> unique_constraint(:issue_id, name: :scenario_statsd_default_unique_issues)
    |> unique_constraint(:issue_id, name: :scenario_statsd_solution_unique_issues)
  end

  def create_changeset(%ScenarioStats{} = scenario_stats, attrs) do
    scenario_stats
    |> base_changeset(attrs)
    |> add_validations
  end

  def update_changeset(%ScenarioStats{} = scenario_stats, attrs) do
    scenario_stats
    |> base_changeset(attrs)
    |> add_validations
  end
end
