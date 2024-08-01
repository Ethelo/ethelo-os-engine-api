defmodule EtheloApi.Structure.CopyDecisionImportTest do
  @moduledoc """
  Validations and basic access for "Decision", the base model all config is attached to
  Includes both the context EtheloApi.Structure, and specific functionality on the Decision schema
  """
  use EtheloApi.DataCase
  alias EtheloApi.Structure
  alias EtheloApi.Serialization.DecisionCopy

  @moduletag decision: true, ethelo: true, ecto: true

  describe "copy_decision/0" do
    test "completes" do
      %{decision: decision} = EtheloApi.Blueprints.PizzaProject.build(false)

      result = DecisionCopy.copy(decision, [slug: "copy", title: "copy"])

      assert {:ok, new} = result

    end
  end



end
