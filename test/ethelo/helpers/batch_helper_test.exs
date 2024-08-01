defmodule EtheloApi.Constraints.BatchHelperTest do
  @moduledoc """
  Validations and basic access for FilterBuilder
  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory

  alias EtheloApi.Helpers.BatchHelper
  alias EtheloApi.Structure.Decision

  describe "preloaded_assoc/2" do

    test "returns assoc if preloaded" do
      %{criteria: criteria, decision: decision} = create_criteria()
      %{id: criteria_id} = criteria

      decision = Repo.get(Decision, decision.id)

      result = BatchHelper.preloaded_assoc(decision, :criterias)

      assert {:error, nil} = result

      decision = Repo.preload(decision, :criterias)

      result = BatchHelper.preloaded_assoc(decision, :criterias)

      assert {:ok, [%{id: ^criteria_id}]} = result
    end

  end

end
