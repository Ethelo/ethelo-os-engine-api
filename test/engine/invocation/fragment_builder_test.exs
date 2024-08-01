defmodule Engine.Invocation.FragmentBuilderTest do
  @moduledoc false
  use EtheloApi.DataCase

  alias Engine.Invocation.FragmentBuilder

  @fixture TestSupport.PizzaProjectData.scoring_data()

  test "builds fragments segments" do

    result = FragmentBuilder.fragments_segment(@fixture)

    assert %{fragments: list} = result
    assert is_list(list)

    assert %{code: "mean[i in x]{$Dcost[i]}", name: "avg_cost"} in list
    assert %{code: "mean[i in x]{$Dinches[i]}", name: "avg_inches"} in list
    assert %{code: "$Gall_options", name: "count_all_options"} in list
    assert %{code: "$Gcheese_no", name: "count_cheese_no"} in list
    assert %{code: "$Gcheese_yes", name: "count_cheese_yes"} in list
    assert %{code: "$Gm_at_1", name: "count_m_at"} in list
    assert %{code: "$Guncategorized_options", name: "count_uncategorized_options"}  in list
    assert %{code: "$Gvegetarian_1", name: "count_vegetarian_1"} in list
    assert %{code: "$Gvegetarian_no", name: "count_vegetarian_no"}  in list
    assert %{code: "$Gvegetarian_yes", name: "count_vegetarian_yes"} in list
    assert %{code: "$Gxorcat", name: "count_xorcat"} in list
    assert %{code: "$Gxorcat2", name: "count_xorcat2"} in list
    assert %{code: "$Dcost", name: "total_cost"} in list
    assert %{code: "$Dinches", name: "total_inches"} in list

    assert [_, _, _, _,  _, _, _, _,  _, _, _, _,  _, _] = list
  end


end
