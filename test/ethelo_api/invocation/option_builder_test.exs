defmodule EtheloApi.Invocation.OptionBuilderTest do
  @moduledoc false

  use ExUnit.Case

  alias EtheloApi.Invocation.OptionBuilder
  @fixture TestSupport.PizzaProjectData.scoring_data()

  test "builds Option segments" do
    result = OptionBuilder.options_segment(@fixture)

    assert %{options: list} = result
    assert [one, two, three, four, five, six, _] = list

    assert one == %{
             name: "pepperoni_mushroom",
             determinative: true,
             details: [
               %{name: "Cmèat", value: 1},
               %{name: "Dcost", value: 1_800_000},
               %{name: "Dinches", value: 1_400_000},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 1},
               %{name: "Gcheese_yes", value: 0},
               %{name: "Gm_at_1", value: 1},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 0},
               %{name: "Gvegetarian_no", value: 1},
               %{name: "Gvegetarian_yes", value: 0},
               %{name: "Gxorcat", value: 0},
               %{name: "Gxorcat2", value: 0}
             ]
           }

    assert two == %{
             name: "large_cheese",
             determinative: false,
             details: [
               %{name: "Cvegetarian", value: 1},
               %{name: "Dcost", value: 30001},
               %{name: "Dinches", value: 20},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 0},
               %{name: "Gcheese_yes", value: 1},
               %{name: "Gm_at_1", value: 0},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 1},
               %{name: "Gvegetarian_no", value: 0},
               %{name: "Gvegetarian_yes", value: 1},
               %{name: "Gxorcat", value: 0},
               %{name: "Gxorcat2", value: 0}
             ]
           }

    assert three == %{
             name: "regular_cheese",
             determinative: false,
             details: [
               %{name: "Cvegetarian", value: 1},
               %{name: "Dcost", value: 12000.25},
               %{name: "Dinches", value: 14},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 0},
               %{name: "Gcheese_yes", value: 1},
               %{name: "Gm_at_1", value: 0},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 1},
               %{name: "Gvegetarian_no", value: 0},
               %{name: "Gvegetarian_yes", value: 1},
               %{name: "Gxorcat", value: 0},
               %{name: "Gxorcat2", value: 0}
             ]
           }

    assert four == %{
             name: "mèat_lovers",
             determinative: false,
             details: [
               %{name: "Cmèat", value: 1},
               %{name: "Dcost", value: 22.95},
               %{name: "Dinches", value: 14},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 1},
               %{name: "Gcheese_yes", value: 0},
               %{name: "Gm_at_1", value: 1},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 0},
               %{name: "Gvegetarian_no", value: 1},
               %{name: "Gvegetarian_yes", value: 0},
               %{name: "Gxorcat", value: 0},
               %{name: "Gxorcat2", value: 0}
             ]
           }

    assert five == %{
             name: "veggie_lovers",
             determinative: false,
             details: [
               %{name: "Cvegetarian", value: 1},
               %{name: "Dcost", value: 18.75},
               %{name: "Dinches", value: 14},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 1},
               %{name: "Gcheese_yes", value: 0},
               %{name: "Gm_at_1", value: 0},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 1},
               %{name: "Gvegetarian_no", value: 0},
               %{name: "Gvegetarian_yes", value: 1},
               %{name: "Gxorcat", value: 0},
               %{name: "Gxorcat2", value: 0}
             ]
           }

    assert six == %{
             name: "xor-1",
             determinative: false,
             details: [
               %{name: "Cxorcat", value: 1},
               %{name: "Dcost", value: 0},
               %{name: "Dinches", value: 0},
               %{name: "Gall_options", value: 1},
               %{name: "Gcheese_no", value: 0},
               %{name: "Gcheese_yes", value: 0},
               %{name: "Gm_at_1", value: 0},
               %{name: "Guncategorized_options", value: 0},
               %{name: "Gvegetarian_1", value: 0},
               %{name: "Gvegetarian_no", value: 0},
               %{name: "Gvegetarian_yes", value: 0},
               %{name: "Gxorcat", value: 1},
               %{name: "Gxorcat2", value: 0}
             ]
           }
  end
end
