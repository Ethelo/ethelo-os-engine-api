require IEx

defmodule EtheloApi.Blueprints.QuickBuilder do
  @moduledoc "Generates a decision matching the pizza project "

  import EtheloApi.Structure.Factory
  import EtheloApi.Voting.Factory
  import Engine.Scenarios.Factory

  def decision_id(%{decision: decision_id}), do: decision_id

  def add_decision(data, decision_content) do
    Map.put(data, :decision, create_decision(decision_content))
  end

  def add_criterias(data, nil), do:  Map.put(data, :criterias, nil)
  def add_criterias(%{decision: decision} = data, criteria_content) do
    criterias =
      criteria_content
      |> Enum.map(fn row ->
        [key, bins, support_only, title, slug, info, apply_participant_weights] = row

        criteria =
          create_criteria_without_deps(
            decision,
            %{
              bins: bins,
              support_only: support_only,
              title: title,
              slug: slug,
              info: info,
              apply_participant_weights: apply_participant_weights
            }
          )

        {key, criteria}
      end)
      |> Enum.into(%{})

    Map.put(data, :criterias, criterias)
  end

  def add_option_details(data, nil), do:  Map.put(data, :option_details, nil)
  def add_option_details(%{decision: decision} = data, option_detail_content) do
    option_details =
      option_detail_content
      |> Enum.map(fn row ->
        [key, format, title, slug, public] = row

        option_detail =
          create_option_detail_without_deps(
            decision,
            %{format: format, title: title, slug: slug, public: public}
          )

        {key, option_detail}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_details, option_details)
  end

  def add_option_categories(data, nil), do:  Map.put(data, :option_categories, nil)
  def add_option_categories(
        %{decision: decision, option_details: option_details} = data,
        option_category_content
      ) do
    option_categories =
      option_category_content
      |> Enum.map(fn row ->
        [
          key,
          title,
          slug,
          info,
          weighting,
          xor,
          scoring_mode,
          primary_detail_key,
          triangle_base,
          apply_participant_weights,
          voting_style,
          quadratic
        ] = row

        primary_detail = option_details[primary_detail_key]

        option_category =
          create_option_category_without_deps(
            decision,
            %{
              title: title,
              slug: slug,
              info: info,
              weighting: weighting,
              xor: xor,
              scoring_mode: scoring_mode,
              primary_detail: primary_detail,
              triangle_base: triangle_base,
              apply_participant_weights: apply_participant_weights,
              voting_style: voting_style,
              quadratic: quadratic,
            }
          )

        {key, option_category}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_categories, option_categories)
  end

  def add_seed_options_and_values(data, nil) do
    data
    |> Map.put( :options, [])
    |> Map.put( :option_detail_values, [])
  end
  def add_seed_options_and_values(
    %{} = data,
    seed_option_content,
    seeds
    ) do

    content = seed_option_content
      |> Enum.reduce(%{options: [], odvs: []}, fn row, memo ->
        [key_base, option_category_key] = row

        seeds
        |> Enum.reduce(memo, fn seed, memo2 ->
          option_slug = "#{key_base}_seed#{seed}"
          option_key = String.to_atom(option_slug)

          option = [option_key, "#{seed} Seeds", option_slug, option_category_key, "", true ]
          odv = [option_key, :seeds, seed ]

          option_list = Map.get(memo2, :options)
          memo2 = Map.put(memo2, :options, option_list ++ [option])

          odv_list = Map.get(memo2, :odvs)
          memo2 = Map.put(memo2, :odvs, odv_list ++ [odv])

          memo2
        end)

    end)

    data
    |> add_options( content[:options] )
    |> add_option_detail_values( content[:odvs] )
  end

  def add_options(data, nil), do:  Map.put(data, :options, [])
  def add_options(
        %{decision: decision, option_categories: option_categories} = data,
        option_content
      ) do
    options =
      option_content
      |> Enum.map(fn row ->
        [key, title, slug, option_category_key, info, enabled] = row

        option_category = option_categories[option_category_key]

        option =
          create_option_without_deps(
            decision,
            %{
              title: title,
              slug: slug,
              option_category: option_category,
              info: info,
              enabled: enabled,
            }
          )

        {key, option}
      end)
      |> Enum.into(%{})

    Map.put(data, :options, options)
  end

  def add_option_detail_values(data, nil), do:  Map.put(data, :option_detail_values, [])
  def add_option_detail_values(
        %{options: options, option_details: option_details} = data,
        odv_content
      ) do
    option_detail_values =
      odv_content
      |> Enum.map(fn row ->
        [option_key, option_detail_key, value] = row

        option = options[option_key]
        option_detail = option_details[option_detail_key]

        create_option_detail_value(option, option_detail, value)
      end)

    Map.put(data, :option_detail_values, option_detail_values)
  end

  def add_option_filters(data, nil), do:  Map.put(data, :option_filters, [])
  def add_option_filters(
        %{decision: decision, option_details: option_details} = data,
        option_filter_content
      ) do
    option_filters =
      option_filter_content
      |> Enum.map(fn row ->
        [
          key,
          option_detail_key,
          match_mode,
          match_value,
          title,
          slug
        ] = row

        option_detail = option_details[option_detail_key]

        option_filter =
          create_option_filter_without_deps(
            decision,
            %{
              option_detail: option_detail,
              match_mode: match_mode,
              match_value: match_value,
              title: title,
              slug: slug,
              }
          )

        {key, option_filter}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_filters, option_filters)
  end

  def add_variables(data, nil), do:  Map.put(data, :variables, [])
  def add_variables(
        %{decision: decision, option_details: option_details, option_filters: option_filters} =
          data,
        variable_content
      ) do
    variables =
      variable_content
      |> Enum.map(fn row ->
        [
          key,
          option_detail_key,
          option_filter_key,
          method,
          title,
          slug
        ] = row

        option_detail = option_details[option_detail_key]
        option_filter = option_filters[option_filter_key]

        variable =
          create_variable_without_deps(
            decision,
            %{
              option_detail: option_detail,
              option_filter: option_filter,
              method: method,
              title: title,
              slug: slug
            }
          )

        {key, variable}
      end)
      |> Enum.into(%{})

    Map.put(data, :variables, variables)
  end

  def add_constraints(data, nil), do:  Map.put(data, :constraints, [])
  def add_constraints(
        %{
          decision: decision,
          variables: variables,
          calculations: calculations,
          option_filters: option_filters
        } = data,
        constraint_content
      ) do
    constraints =
      constraint_content
      |> Enum.map(fn row ->
        [
          key,
          variable_key,
          calculation_key,
          operator,
          rhs,
          title,
          slug,
          option_filter_key
        ] = row

        variable = variables[variable_key]
        calculation = calculations[calculation_key]
        option_filter = option_filters[option_filter_key]

        constraint =
          create_constraint_without_deps(
            decision,
            %{
              variable: variable,
              calculation: calculation,
              operator: operator,
              rhs: rhs,
              title: title,
              slug: slug,
              option_filter: option_filter
            }
          )

        {key, constraint}
      end)
      |> Enum.into(%{})

    Map.put(data, :constraints, constraints)
  end

  def add_participants(data, nil), do:  Map.put(data, :participants, [])
  def add_participants(%{decision: decision} = data, participant_content) do
    participants =
      participant_content
      |> Enum.map(fn row ->
        [key, weighting] = row

        participant =
          create_participant_without_deps(
            decision,
            %{weighting: weighting}
          )

        {key, participant}
      end)
      |> Enum.into(%{})

    Map.put(data, :participants, participants)
  end

  def add_bin_votes(data, nil), do:  Map.put(data, :bin_votes, [])
  def add_bin_votes(
        %{decision: decision, options: options, criterias: criterias, participants: participants} =
          data,
        bin_vote_content
      ) do
    bin_votes =
      bin_vote_content
      |> Enum.map(fn row ->
        [participant_key, option_key, criteria_key, bin] = row

        participant = participants[participant_key]
        option = options[option_key]
        criteria = criterias[criteria_key]

        create_bin_vote_without_deps(
          decision,
          %{
            participant: participant,
            option: option,
            criteria: criteria,
            bin: bin
          }
        )
      end)

    Map.put(data, :bin_votes, bin_votes)
  end

  def add_option_category_range_votes(data, nil), do:  Map.put(data, :option_category_range_votes, [])
  def add_option_category_range_votes(
        %{
          decision: decision,
          options: options,
          option_categories: option_categories,
          participants: participants
        } = data,
        option_category_range_vote_content
      ) do

    option_category_range_votes =
      option_category_range_vote_content
      |> Enum.map(fn row ->
        [participant_key, low_option_key, high_option_key, option_category_key] = row

        participant = participants[participant_key]
        low_option = options[low_option_key]
        high_option = options[high_option_key]
        option_category = option_categories[option_category_key]

        option_category_range_vote =
          create_option_category_range_vote_without_deps(
            decision,
            %{
              participant: participant,
              low_option: low_option,
              high_option: high_option,
              option_category: option_category
            }
          )

        option_category_range_vote
      end)

    Map.put(data, :option_category_range_votes, option_category_range_votes)
  end

  def add_criteria_weights(data, nil), do:  Map.put(data, :criteria_weights, [])
  def add_criteria_weights(
        %{decision: decision, criterias: criterias, participants: participants} = data,
        criteria_weight_content
      ) do
    criteria_weights =
      criteria_weight_content
      |> Enum.map(fn row ->
        [participant_key, criteria_key, weighting] = row

        participant = participants[participant_key]
        criteria = criterias[criteria_key]

        create_criteria_weight_without_deps(
          decision,
          %{
            participant: participant,
            criteria: criteria,
            weighting: weighting
          }
        )
      end)

    Map.put(data, :criteria_weights, criteria_weights)
  end

  def add_option_category_weights(data, nil), do:  Map.put(data, :option_category_weights, [])
  def add_option_category_weights(
        %{decision: decision, option_categories: option_categories, participants: participants} =
          data,
        option_category_weight_content
      ) do
    option_category_weights =
      option_category_weight_content
      |> Enum.map(fn row ->
        [participant_key, option_category_key, weighting] = row

        participant = participants[participant_key]
        option_category = option_categories[option_category_key]

        create_option_category_weight_without_deps(
          decision,
          %{
            participant: participant,
            option_category: option_category,
            weighting: weighting
          }
        )
      end)

    Map.put(data, :option_category_weights, option_category_weights)
  end

  def add_option_category_weights(data, nil), do:  Map.put(data, :scenario_config, nil)
  def add_scenario_config(%{decision: decision} = data, scenario_config_content) do
    scenario_config = create_scenario_config_without_deps(decision, scenario_config_content)
    Map.put(data, :scenario_config, scenario_config)
  end
end
