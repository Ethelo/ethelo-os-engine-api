defmodule GraphQL.EtheloApi.ResolveHelper do
  @moduledoc """
  Utilities for common resolve operations
  """
  require OK
  alias EtheloApi.Structure
  use OK.Pipe

  alias Kronky.ValidationMessage

  def success(value), do: {:ok, value}

  def sanitize_id(id) do
    if is_nil(id) or id === 0 or id == "0" do
      nil
    else
      id
    end
  end

  def verify_id(_module, _field, nil), do: :ok
  def verify_id(module, field, id) do
    case EtheloApi.Repo.get(module, id) do
      nil -> {:error, %ValidationMessage{field: field, code: :not_found, message: "does not exist", template: "does not exist"}}
      _   -> :ok
    end
  end

  def verify_id(_module, _field, nil, _decision_id), do: :ok
  def verify_id(module, field, id, decision_id) do
    case EtheloApi.Repo.get_by(module, id: id, decision_id: decision_id) do
      nil -> {:error, %ValidationMessage{field: field, code: :not_found, message: "does not exist", template: "does not exist"}}
      _   -> :ok
    end
  end

  def verify_ids([]), do: :ok
  def verify_ids([{module, field, id} | tail]) do
    case verify_id(module, field, id) do
      :ok -> verify_ids(tail)
      {:error, value} -> {:error, value}
    end
  end
  def verify_ids([{module, field, id, decision_id} | tail]) do
    case verify_id(module, field, id, decision_id) do
      :ok -> verify_ids(tail)
      {:error, value} -> {:error, value}
    end
  end

  def verify_ids(id_list, decision_id) do
    Enum.map(id_list, fn({module, field, id}) ->
      {module, field, id, decision_id} end) |> verify_ids
  end

  def verify_decision(%{decision_id: id}), do: get_decision(id, :decision_id)
  def verify_decision(%{input: %{decision_id: id}}), do: get_decision(id, :decision_id)
  def verify_decision(%{id: id}), do: get_decision(id, :id)
  def verify_decision(%{input: %{id: id}}), do: get_decision(id, :id)
  def verify_decision(id), do: get_decision(id, :id)

  def get_decision(id, field) do
    verify_required(Structure.get_decision(id), field)
  end

  def verify_required(struct, field) do
    if is_nil(struct) do
      field = field |> to_string() |> Absinthe.Utils.camelize(lower: true)
      {:error, %ValidationMessage{field: field, code: :not_found, message: "does not exist", template: "does not exist"}}
    else
      {:ok, struct}
    end
  end

  def mutation_resolver(func) do
    fn(args, _resolution) ->
      OK.try do
        input = Map.get(args, :input, %{})
        result <- args |> verify_decision() ~>> func.(input)
      after
        {:ok, result}
      rescue
        %ValidationMessage{} = message -> success(message)
        %Ecto.Changeset{} = changeset -> success(changeset)
        message -> success(%ValidationMessage{code: :error, message: message})
      end
    end
  end

  def not_found_error() do
    {:ok, %ValidationMessage{field: :id, code: :not_found, message: "does not exist", template: "does not exist"}}
  end

end
