defmodule EtheloApi.Structure.Docs.ScenarioConfig do
  @moduledoc "Central repository for documentation strings about ScenarioConfigs."

  require DocsComposer

  @decision_id "The Decision the ScenarioConfig belongs to."

  @title "Name of ScenarioConfig. Used to generate slug if none supplied"

  @bins """
  The number of vote increments to allow, between one and nine.

  These will correspond to the number of buttons or inputs on the presentation layer. While the actual interface is up to the presentation layer, we recommend using a Likert Scale.

  For example, if a ScenarioConfig has 5 bins, then presentation layer could show 5 buttons:
  [Strongly Disapprove] [Disapprove] [Neutral] [Approve] [Strongly Approve]
  """

  @skip_solver """
  A boolean that indicates whether or not to skip invoking the solver on the Decision when generating Scenarios.

  If enabled only the global "all options" Scenario will be generated and added to the resulting ScenarioSet.
  """

  @normalize_satisfaction """
  A boolean that indicates whether satisfaction scores should be normalized between the actual minimum and maximum scores possible.
  """

  @normalize_influents """
  A boolean that indicates whether Participant scores should be normalized.

  Normalization of scores means adjusting values measured on different scales to a notionally common scale.
  """

  @support_only """
  A boolean that indicates if the ScenarioConfig should not include "disapproval" values. Defaults to "false".

  The Ethelo algorithm takes into account how polarizing a Decision is - if many people are "for" or "against" an option, it will affect the score.

  By default, the system assumes that a vote in the lower bins indicates disapproval - people who use these values are against the Option.
  Bins are distributed from "Extremely Against" to "Neutral" to "Extremely Support".

  When "support only" is enbabled, then the assumption changes. Votes in the lower bins are instead considered neutral votes.
  Bins are distributed from "Neutral" to "Extremely Support".
  """

  @per_option_satisfaction """
  A boolean flag that controls whether or not the Ethelo engine divides satisfaction scores by the number of selected Options in the Scenario.
  """

  @collective_identity """
  ≡  = Collective Identity
  Unity has a different relevance in different Decision contexts because the phenomenon in which a Decision becomes more powerful through unity is a social phenomenon; it doesn’t appear if there is only one Participant.

  For example, in a process where Participants do not have relationships or the sense of reciprocity that arises in community, it may not be important that Participants experience similar levels of support for solutions, or feel that influence in shaping the solutions was distributed fairly. However, in a stakeholder process where there are entitlements resting on a collective identity, then fairness in support distribution can be quite important. ≡ represents the importance of unity in a specific Decision context.

  Collective Identity (≡) determines the impact of Unity on a Decision. The higher the Collective Identity value, the more important it is that the selected solutions have similar levels of support across Participants.
  """

  @scenario_config """
  ScenarioConfigs hold the settings used when calculating Scenarios for a Decision.
  """

  @max_scenarios "The maximum number of Scenarios to generate. The actual number of Scenarios returned cannot be guaranteed."

  @tipping_point """
  As consensus for a Scenarios decreases, there will be a “tipping point” when people will cease to resist the solutions because of inequality aversion, and begin to support it due to fairness and the unity it creates. Where this neutral tipping point is found will depend on the type of Decision process and group dynamics.  By default, we set the tipping point at about 1/3rds consensus.
  """

  @enabled """
  A boolean that indicates if the ScenarioConfig is the setting currently being used. Only one ScenarioConfig will ever be enabled at a time.
  """

  @solve_interval "The length of time in milliseconds to wait between solver invocations."

  @ttl "The length of time in seconds to wait before discarding results generated with this config. Defaults to 0, or 'Never', which will grow the database very quickly. "

  @engine_timeout "Max amount of time in milliseconds to allow engine to run. "

  @quadratic """
  Toggles if quadratic analysis should be run
  """

  @quad_user_seeds "Number of seeds allocated for a Participant in quadratic voting"
  @quad_total_available "Total amount available in quadratic voting"
  @quad_cutoff "Minimum amount allowed in quadratic voting grant"
  @quad_max_allocation "Max amount allowed in quadratic voting grant"
  @quad_round_to "Amount to round to in quadratic voting grant"
  @quad_seed_percent "Percent of total available to be allocated by seed count"
  @quad_vote_percent "Percent of total available to be allocated by vote count"

  defp scenario_config_fields() do
    [
      %{
        name: :title,
        info: @title,
        type: :string,
        validation: "Must include at least one word",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :bins,
        info: @bins,
        type: :integer,
        required: true,
        validation: "between 1 and 9",
        automatic: false,
        immutable: false
      },
      %{
        name: :max_scenarios,
        info: @max_scenarios,
        type: :integer,
        validation: "between 1 and 20",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: "ci/collective identity",
        info: @collective_identity,
        type: "decimal(8,7)",
        validation: "between 0 and 1",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :tipping_point,
        info: @tipping_point,
        type: "decimal(8,7)",
        validation: "between 0 and 1",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :normalize_satisfaction,
        info: @normalize_satisfaction,
        type: :boolean,
        required: false
      },
      %{name: :normalize_influents, info: @normalize_influents, type: :boolean, required: false},
      %{name: :skip_solver, info: @skip_solver, type: :boolean, required: false},
      %{name: :support_only, info: @support_only, type: :boolean, required: false},
      %{
        name: :per_option_satisfaction,
        info: @per_option_satisfaction,
        type: :boolean,
        required: false
      },
      %{name: :solve_interval, info: @solve_interval, type: :integer, required: false},
      %{name: :ttl, info: @ttl, type: :integer, required: false},
      %{
        name: :engine_timeout,
        info: @engine_timeout,
        type: :integer,
        required: true,
        default: 900
      },
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{name: :enabled, info: @enabled, type: :boolean, required: false},
      %{name: :quadratic, info: @quadratic, type: :boolean, required: false},
      %{name: :quad_user_seeds, info: @quad_user_seeds, type: :integer, required: false},
      %{
        name: :quad_total_available,
        info: @quad_total_available,
        type: :integer,
        required: false
      },
      %{name: :quad_cutoff, info: @quad_cutoff, type: :integer, required: false},
      %{name: :quad_max_allocation, info: @quad_max_allocation, type: :integer, required: false},
      %{name: :quad_round_to, info: @quad_round_to, type: :integer, required: false},
      %{name: :quad_seed_percent, info: @quad_seed_percent, type: :float, required: false},
      %{name: :quad_vote_percent, info: @quad_vote_percent, type: :flat, required: false}
    ]
  end

  @doc """
  a list of maps describing all ScenarioConfig schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :inserted_at, :updated_at]) ++
      scenario_config_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Standard" => %{
        id: 1,
        title: "Default",
        slug: "default",
        bins: 5,
        ci: Decimal.from_float(0.0),
        skip_solver: false,
        support_only: false,
        quadratic: false,
        per_option_satisfaction: false,
        normalize_satisfaction: true,
        normalize_influents: false,
        max_scenarios: 1,
        tipping_point: Decimal.from_float(0.33333),
        enabled: true,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        ttl: 0,
        engine_timeout: 10 * 1000,
        quad_user_seeds: nil,
        quad_total_available: nil,
        quad_cutoff: nil,
        quad_seed_percent: nil,
        quad_max_allocation: nil,
        quad_vote_percent: nil,
        quad_round_to: nil
      },
      "Quadratic" => %{
        id: 2,
        bins: 9,
        title: "CI at 0.5",
        slug: "ci-point-five",
        ci: Decimal.from_float(0.5),
        skip_solver: false,
        support_only: true,
        quadratic: true,
        per_option_satisfaction: false,
        normalize_satisfaction: false,
        normalize_influents: true,
        max_scenarios: 20,
        tipping_point: Decimal.from_float(0.66666),
        enabled: false,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        ttl: 10,
        engine_timeout: 6 * 1000,
        quad_user_seeds: 125,
        quad_total_available: 580_000,
        quad_cutoff: 7500,
        quad_seed_percent: 0.75,
        quad_vote_percent: 0.25,
        quad_max_allocation: 50_000,
        quad_round_to: 5000
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario_configs"
  """
  def strings() do
    scenario_config_strings = %{
      bins: @bins,
      ci: @collective_identity,
      collective_identity: @collective_identity,
      decision_id: @decision_id,
      enabled: @enabled,
      engine_timeout: @engine_timeout,
      max_scenarios: @max_scenarios,
      quad_cutoff: @quad_cutoff,
      quad_max_allocation: @quad_max_allocation,
      quad_round_to: @quad_round_to,
      quad_seed_percent: @quad_seed_percent,
      quad_total_available: @quad_total_available,
      quad_user_seeds: @quad_user_seeds,
      quad_vote_percent: @quad_vote_percent,
      quadratic: @quadratic,
      normalize_influents: @normalize_influents,
      normalize_satisfaction: @normalize_satisfaction,
      per_option_satisfaction: @per_option_satisfaction,
      scenario_config: @scenario_config,
      skip_solver: @skip_solver,
      solve_interval: @solve_interval,
      support_only: @support_only,
      tipping_point: @tipping_point,
      title: @title,
      ttl: @ttl
    }

    DocsComposer.common_strings() |> Map.merge(scenario_config_strings)
  end
end
