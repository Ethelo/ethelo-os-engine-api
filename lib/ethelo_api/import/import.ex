defmodule EtheloApi.Import do
  @moduledoc """
  The boundary for the Import system.

  All access to import and export  go through this module.
  To keep code files small, the actual methods are in the /queries folder
  and are linked with defdelegate
  """
  alias EtheloApi.Import.ExportBuilder
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportError

  defdelegate build_from_json(json_export, decision_data), to: ImportProcess

  defdelegate compile_errors(process), to: ImportError
  defdelegate summarize_errors(process), to: ImportError

  defdelegate export_decision(decision), to: ExportBuilder
  defdelegate copy_decision(decision, decision_data), to: ExportBuilder
end
