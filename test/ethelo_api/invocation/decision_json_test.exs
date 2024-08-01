defmodule EtheloApi.Invocation.DecisionJsonTest do
  @moduledoc false
  use ExUnit.Case

  alias EtheloApi.Invocation.DecisionJson
  @fixture TestSupport.PizzaProjectData.scoring_data()

  test "builds json" do
    result_map = DecisionJson.build(@fixture)

    json = DecisionJson.to_json(result_map)

    # IO.inspect(json, printable_limit: :infinity)

    # there shouldn't be any numbers formatted in scientific notation
    refute Regex.match?(~r/\d\.\d+[Ee][+\-]\d\d?/, json)

    assert %{} = parsed = Jason.decode!(json)
    # check that all parts are assembled, the actual content is tested elsewhere
    refute nil = Map.get(parsed, :options)
    refute nil = Map.get(parsed, :fragments)
    refute nil = Map.get(parsed, :displays)
    refute nil = Map.get(parsed, :criteria)
    refute nil = Map.get(parsed, :constraints)
  end
end
