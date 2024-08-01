defmodule EtheloApi.Import.ImportError do
  @moduledoc """
  Error messages from import
  """
  defstruct segment: nil, messages: %{}, data: nil, index: nil
  alias EtheloApi.Import.ImportError
  alias EtheloApi.Import.ImportProcess
  alias AbsintheErrorPayload.ValidationMessage

  import AbsintheErrorPayload.ChangesetParser, only: [extract_messages: 1]

  def changeset_to_error(
        %Ecto.Changeset{} = changeset,
        %{key: key},
        input,
        index \\ nil
      ) do
    messages = changeset |> clean_cast_errors() |> extract_messages()
    %ImportError{segment: key, data: input, messages: messages, index: index}
  end

  def changeset_to_decision_errors(%Ecto.Changeset{} = changeset, decision_data) do
    messages = changeset |> clean_cast_errors() |> extract_messages()

    for %{field: field} = message <- messages do
      input_value = Map.get(decision_data, field)

      %ImportError{segment: field, data: input_value, messages: [message]}
    end
  end

  def clean_cast_errors(%{errors: errors} = changeset) do
    errors =
      for {field, {template, opts}} = error <- errors do
        type = Keyword.get(opts, :type)

        case type do
          {:parameterized, Ecto.Enum, enum} ->
            options =
              opts
              |> Keyword.delete(:type)
              |> Keyword.merge(validation: :inclusion, enum: Map.values(enum.on_load))

            {field, {template, options}}

          {:array, :string} ->
            options =
              opts
              |> Keyword.delete(:type)
              |> Keyword.merge(validation: :format)

            {field, {template, options}}

          _ ->
            error
        end
      end

    Map.put(changeset, :errors, errors)
  end

  def summarize_errors(process) do
    process
    |> compile_errors()
    |> Enum.reduce(%{}, &extract_segment_errors/2)
    |> Map.values()
    |> List.flatten()
  end

  def extract_segment_errors(%{segment: segment_name} = import_error, error_map) do
    if segment_name in ImportProcess.segment_names() do
      group_segment_errors(import_error, error_map)
    else
      segment_errors = Map.get(error_map, segment_name, []) ++ import_error.messages
      Map.put(error_map, segment_name, segment_errors)
    end
  end

  def group_segment_errors(%{segment: segment_name} = import_error, error_map) do
    prefix =
      if is_nil(import_error.index), do: "", else: "Input #{import_error.index + 1}"

    messages =
      for message <- import_error.messages do
        "#{message.field} #{message.message}"
      end
      |> Enum.sort()
      |> Enum.join(", ")

    summary = "#{prefix} #{messages}" |> String.trim(" ")

    grouped_message = %ValidationMessage{
      code: :import_error,
      field: segment_name,
      template: "Could Not Import {segment_name}: {reasons}",
      message: "Could Not Import #{segment_name}: #{summary}",
      options: [segment: segment_name, reason: summary, errors: import_error.messages]
    }

    segment_errors = Map.get(error_map, segment_name, []) ++ [grouped_message]

    Map.put(error_map, segment_name, segment_errors)
  end

  def compile_errors(process) do
    segment_errors =
      Enum.flat_map(ImportProcess.segment_names(), fn name ->
        process
        |> Map.get(name)
        |> case do
          %{errors: errors} -> errors
          _ -> []
        end
      end)

    all_errors = segment_errors ++ [process.input_error]

    Enum.filter(all_errors, &(!is_nil(&1)))
  end

  def add_input_error(reason) do
    message = %ValidationMessage{
      code: :import_file,
      field: :json_data,
      template: "{reason}",
      message: "#{reason}",
      options: [reason: reason]
    }

    input_error = %ImportError{segment: :json_data, data: nil, messages: [message], index: nil}
    {:error, %ImportProcess{input_error: input_error, valid?: false, complete?: false}}
  end

  # line: "2003",
  # detail: "Failing row contains (11433, Total Cost, total_cost, sum_selected, 18293, null, null, 2024-06-16 23:07:26, 2024-06-16 23:07:26).",
  def handle_postgrex_error(%{postgres: %{code: :check_violation} = postgres}, name) do
    options = Map.take(postgres, [:code, :constraint, :detail]) |> Enum.into([])

    message = %ValidationMessage{
      code: :check,
      field: nil,
      template: "Invalid Associations %{constraint}",
      message: "Invalid Associations #{options[:constraint]}",
      options: options
    }

    %ImportError{segment: name, data: nil, messages: [message], index: nil}
  end

  # message: "duplicate key value violates unique constraint \"unique_filter_variable_config_index\"",
  # detail: "Key (option_filter_id, method)=(11396, count_selected) already exists.",
  def handle_postgrex_error(%{postgres: %{code: :unique_violation} = postgres}, name) do
    options = Map.take(postgres, [:code, :constraint, :detail]) |> Enum.into([])

    message = %ValidationMessage{
      code: :unique,
      field: nil,
      template: "Input Must be Unique %{constraint}",
      message: "Input Must be Unique #{options[:constraint]}",
      options: options
    }

    %ImportError{segment: name, data: nil, messages: [message], index: nil}
  end

  def handle_postgrex_error(%{postgres: postgres}, name) do
    IO.inspect(postgres, label: "postgres errors")

    message = %ValidationMessage{
      code: :unknown,
      field: nil,
      template: "Unexpected Error",
      message: "Unexpected Error",
      options: [postgres: postgres]
    }

    %ImportError{segment: name, data: nil, messages: [message], index: nil}
  end

  # credo:disable-for-lines:4 Credo.Check.Refactor.RejectReject
  def invalid_segments(process) do
    ImportProcess.segment_names()
    |> Enum.reject(fn name -> get_in(process, [name]) == nil end)
    |> Enum.reject(fn name -> get_in(process, [name, :valid?]) end)
  end
end
