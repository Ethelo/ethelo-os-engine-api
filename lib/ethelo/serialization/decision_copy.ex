defmodule EtheloApi.Serialization.DecisionCopy do

  require OK

  alias EtheloApi.Structure.Decision

  alias EtheloApi.Serialization.DecisionImport
  alias EtheloApi.Serialization.DecisionExport

  def copy(%Decision{} = decision, options \\ []) do
    OK.for do
      export <- DecisionExport.export(decision)
      decision <- DecisionImport.import(export, options)
    after
      decision
    end
  end

end
