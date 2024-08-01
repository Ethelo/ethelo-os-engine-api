defmodule EtheloApi.Invocation.ConstraintBuilderTest do
  @moduledoc false
  use ExUnit.Case

  alias EtheloApi.Invocation.ConstraintBuilder
  @fixture TestSupport.PizzaProjectData.scoring_data()

  test "builds Constraint segments" do
    result = ConstraintBuilder.constraint_and_display_segments(@fixture)

    assert %{constraints: constraints, displays: displays} = result
    assert is_list(constraints)
    assert is_list(displays)

    assert constraints == [
             %{code: "[@total_cost * 1.20] <= 91000", name: "budget", relaxable: false},
             %{
               code:
                 "[filter[$Gvegetarian_no]{@total_inches * @total_inches * ( 3.14 / 4 ) / 14 - ( 0.2 * @count_cheese_yes )}] >= 2",
               name: "mèat_fed",
               relaxable: false
             },
             %{code: "[@count_vegetarian_no] >= 1", name: "mèat_min", relaxable: false},
             %{code: "[@count_cheese_yes] >= 1", name: "one_cheese", relaxable: false},
             %{
               code:
                 "[filter[$Gvegetarian_yes]{@total_inches * @total_inches * ( 3.14 / 4 ) / 14 - ( 0.2 * @count_cheese_yes )}] >= 2",
               name: "veg_fed",
               relaxable: false
             },
             %{code: "[@count_vegetarian_yes] >= 1", name: "veg_min", relaxable: false},
             %{code: "[@count_xorcat] = 1", name: "__auto_xor11", relaxable: true}
           ]

    assert displays == [
             %{
               code:
                 "@total_inches * @total_inches * ( 3.14 / 4 ) / 14 - ( 0.2 * @count_cheese_yes )",
               name: "feeds"
             },
             %{code: "@count_all_options", name: "pizza_count"},
             %{code: "@total_cost * 1.20", name: "total_cost"}
           ]
  end
end
