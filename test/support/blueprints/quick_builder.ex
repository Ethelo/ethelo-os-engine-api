require IEx

defmodule EtheloApi.Blueprints.QuickBuilder do
  @moduledoc "Utility to generate a complex Decision fixuture  "

  import EtheloApi.Structure.Factory
  import EtheloApi.Voting.Factory

  def offset_date_value(offset) do
    NaiveDateTime.utc_now()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.add(offset)
    |> DateTime.truncate(:second)
  end

  def decision_id(%{decision: decision_id}), do: decision_id

  def add_decision(data, decision_content) do
    Map.put(data, :decision, create_decision(decision_content))
  end

  def add_criterias(data, nil), do: Map.put(data, :criterias, nil)

  def add_criterias(%{decision: decision} = data, criteria_content) do
    criterias =
      criteria_content
      |> Enum.map(fn row ->
        [key, bins, support_only, title, slug, info, apply_participant_weights, weighting] = row

        criteria =
          create_criteria_without_deps(
            decision,
            %{
              bins: bins,
              support_only: support_only,
              title: title,
              slug: slug,
              info: info,
              apply_participant_weights: apply_participant_weights,
              weighting: weighting
            }
          )

        {key, criteria}
      end)
      |> Enum.into(%{})

    Map.put(data, :criterias, criterias)
  end

  def add_option_details(data, nil), do: Map.put(data, :option_details, nil)

  def add_option_details(%{decision: decision} = data, option_detail_content) do
    option_details =
      option_detail_content
      |> Enum.map(fn row ->
        [key, format, title, slug, public, sort, input_hint, display_hint] = row

        option_detail =
          create_option_detail_without_deps(
            decision,
            %{
              format: format,
              title: title,
              slug: slug,
              public: public,
              sort: sort,
              input_hint: input_hint,
              display_hint: display_hint
            }
          )

        {key, option_detail}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_details, option_details)
  end

  def parse_option_category_array(value_list) do
    [key, title, slug, info, results_title | part2] = value_list
    [weighting, apply_participant_weights | part3] = part2
    [xor, scoring_mode, triangle_base, voting_style, primary_detail_key | part4] = part3
    [quadratic, budget_percent, flat_fee, vote_on_percent, keywords] = part4

    values = %{
      apply_participant_weights: apply_participant_weights,
      budget_percent: budget_percent,
      flat_fee: flat_fee,
      info: info,
      keywords: keywords,
      primary_detail_key: primary_detail_key,
      quadratic: quadratic,
      results_title: results_title,
      scoring_mode: scoring_mode,
      slug: slug,
      title: title,
      triangle_base: triangle_base,
      vote_on_percent: vote_on_percent,
      voting_style: voting_style,
      weighting: weighting,
      xor: xor
    }

    {key, values}
  end

  def add_option_categories(data, nil), do: Map.put(data, :option_categories, nil)

  def add_option_categories(
        %{decision: decision, option_details: option_details} = data,
        option_category_content
      ) do
    option_categories =
      option_category_content
      |> Enum.map(fn row ->
        {key, values} = parse_option_category_array(row)
        %{primary_detail_key: primary_detail_key, keywords: keywords} = values

        primary_detail = option_details[primary_detail_key]

        {:ok, keywords} = Jason.encode(keywords)

        values =
          values
          |> Map.put(:primary_detail, primary_detail)
          |> Map.put(:keywords, keywords)

        option_category = create_option_category_without_deps(decision, values)

        {key, option_category}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_categories, option_categories)
  end

  def update_option_categories(data, nil), do: data

  def update_option_categories(
        %{options: options, option_categories: option_categories} = data,
        oc_assoc_content
      ) do
    for row <- oc_assoc_content, reduce: data do
      data ->
        [option_category_key, default_high_option_key, default_low_option_key] = row
        option_category = option_categories[option_category_key]
        default_high_option = options[default_high_option_key]
        default_low_option = options[default_low_option_key]

        option_category =
          update_option_category(option_category, %{
            default_high_option_id: default_high_option.id,
            default_low_option_id: default_low_option.id
          })

        update_keyed(data, :option_categories, option_category_key, option_category)
    end
  end

  def add_seed_options_and_values(data, nil) do
    data
    |> Map.put(:options, [])
    |> Map.put(:option_detail_values, [])
  end

  def add_seed_options_and_values(
        %{} = data,
        seed_option_content,
        seeds
      ) do
    data_list = %{options: [], odvs: [], oc_assocs: []}

    content =
      for row <- seed_option_content, reduce: data_list do
        data_list ->
          [_, option_category_key] = row
          seed_data = for seed <- seeds, do: build_seed_data(row, seed)

          options = Enum.flat_map(seed_data, &Map.get(&1, :options))
          odvs = Enum.flat_map(seed_data, &Map.get(&1, :odvs))

          first_option_key = options |> hd() |> hd()
          oc_assocs = [[option_category_key, first_option_key, first_option_key]]

          data_list
          |> add_to_list(:options, options)
          |> add_to_list(:odvs, odvs)
          |> add_to_list(:oc_assocs, oc_assocs)
      end

    data
    |> add_options(content[:options])
    |> add_option_detail_values(content[:odvs])
    |> update_option_categories(content[:oc_assocs])
  end

  def build_seed_data(row, seed) do
    [key_base, option_category_key] = row

    option_slug = "#{key_base}_seed#{seed}"
    option_key = String.to_atom(option_slug)

    option = [option_key, "#{seed} Seeds", option_slug, option_category_key, nil, true]
    odv = [option_key, :seeds, seed]

    %{options: [option], odvs: [odv]}
  end

  def add_options(data, nil), do: Map.put(data, :options, [])

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
              enabled: enabled
            }
          )

        {key, option}
      end)
      |> Enum.into(%{})

    Map.put(data, :options, options)
  end

  def add_option_detail_values(data, nil), do: Map.put(data, :option_detail_values, [])

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

  def add_option_filters(data, nil), do: Map.put(data, :option_filters, [])

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
              slug: slug
            }
          )

        {key, option_filter}
      end)
      |> Enum.into(%{})

    Map.put(data, :option_filters, option_filters)
  end

  def add_variables(data, nil), do: Map.put(data, :variables, [])

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

  def add_constraints(data, nil), do: Map.put(data, :constraints, [])

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

  def add_participants(data, nil), do: Map.put(data, :participants, [])

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

  def add_bin_votes(data, nil), do: Map.put(data, :bin_votes, [])

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
            bin: bin,
            updated_at: offset_date_value(Enum.random(-2000..-1000))
          }
        )
      end)

    Map.put(data, :bin_votes, bin_votes)
  end

  def add_option_category_range_votes(data, nil),
    do: Map.put(data, :option_category_range_votes, [])

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
              option_category: option_category,
              updated_at: offset_date_value(Enum.random(-1000..-100))
            }
          )

        option_category_range_vote
      end)

    Map.put(data, :option_category_range_votes, option_category_range_votes)
  end

  def add_criteria_weights(data, nil), do: Map.put(data, :criteria_weights, [])

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
            weighting: weighting,
            updated_at: offset_date_value(Enum.random(-1000..-100))
          }
        )
      end)

    Map.put(data, :criteria_weights, criteria_weights)
  end

  def add_option_category_weights(data, nil), do: Map.put(data, :option_category_weights, [])

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
            weighting: weighting,
            updated_at: offset_date_value(Enum.random(-1000..-100))
          }
        )
      end)

    Map.put(data, :option_category_weights, option_category_weights)
  end

  def add_option_category_weights(data, nil), do: Map.put(data, :scenario_config, nil)

  def add_scenario_config(%{decision: decision} = data, scenario_config_content) do
    scenario_config = create_scenario_config_without_deps(decision, scenario_config_content)
    Map.put(data, :scenario_config, scenario_config)
  end

  def add_to_list(map, list_field, new_items) do
    current_list = Map.get(map, list_field)
    new_list = current_list ++ new_items
    Map.put(map, list_field, new_list)
  end

  def update_keyed(map, list_field, new_key, new_value) do
    current_list = Map.get(map, list_field)
    new_list = Map.put(current_list, new_key, new_value)
    Map.put(map, list_field, new_list)
  end
end
