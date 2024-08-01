defmodule EtheloApi.Serialization.DecisionExport do

  alias EtheloApi.Serialization.Export
  alias EtheloApi.Structure.Decision

  def export(%Decision{} = decision, options \\ []) do
    options = options |> Keyword.put(:to_export, [
      options: [], option_detail_values: [], option_categories: [], criterias: [], option_details: [],
      option_filters: [], constraints: [], variables: [], calculations: [],
      scenario_configs: [],
      ])
    Export.export(decision, options)
  end

end
