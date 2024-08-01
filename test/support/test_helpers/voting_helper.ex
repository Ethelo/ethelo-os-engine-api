defmodule EtheloApi.Structure.TestHelper.VotingHelper do
  @moduledoc false
    
    def add_participant_id(attrs, %{participant: participant}), do: Map.put(attrs, :participant_id, participant.id)
    def add_participant_id(attrs, _deps), do: attrs

    def add_option_id(attrs, %{option: option}), do: Map.put(attrs, :option_id, option.id)
    def add_option_id(attrs, _deps), do: attrs

    def add_criteria_id(attrs, %{criteria: criteria}), do: Map.put(attrs, :criteria_id, criteria.id)
    def add_criteria_id(attrs, _deps), do: attrs

    def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
    def add_decision_id(attrs, _deps), do: attrs

    def add_option_category_id(attrs, %{option_category: option_category}), do: Map.put(attrs, :option_category_id, option_category.id)
    def add_option_category_id(attrs, _deps), do: attrs


end
