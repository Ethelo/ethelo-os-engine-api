defmodule EtheloApi.Serialization.Import do
  require Logger

  defmodule ImportError do
    defstruct field: nil,
              reason: nil,
              data: nil

    def to_string(%ImportError{field: field, reason: reason}) do
      case {field, reason} do
        {field, {reason, message}} when not is_nil(field) and is_atom(field) and is_atom(reason) ->
          "[#{field}] #{reason}: #{inspect message}"
        {field, reason} when not is_nil(field) and is_atom(field) ->
          "[#{field}] #{inspect reason}"
        {_, {reason, message}} when is_atom(reason) ->
          "#{reason}: #{inspect message}"
        {_, reason} ->
          "#{inspect reason}"
      end
    end
  end

  defmodule ImportIndex do
    defstruct export: nil, imported: %{}, decision: nil, errors: %{}

    @doc """
    Given a pair consisting of a source schema type and field on a row,
    cross reference to find the id of the imported copy

    ## Examples

        iex> lookup_ids(%ImportIndex{imported: %{options: 12: {id: 32}}},
          %{option_id: 12}, [{:options, :option_id}])
        %{option_id: 32}

    """
    def lookup_ids(%ImportIndex{} = index, row, field_pairs) do
      Enum.reduce(field_pairs, %{}, fn({schema, foreign_key}, acc) ->
        old_id = Map.get(row, Atom.to_string(foreign_key))
        new_id = get_in(index, [:imported, schema, old_id, :id ])

        case new_id do
          nil -> acc
          _   -> Map.put(acc, foreign_key, new_id)
        end
      end)
    end

  end


  defmodule Context do
    defstruct export: nil,
              options: [],
              decision: nil,
              fields: %{}

    def add_one(%{export: export} = context, :decision, add_proc) do
      Logger.debug("importing decision")

      case add_proc.(context, export) do
        {:ok, result} -> {:ok, %Context{context | decision: result}}
        {:error, reason} -> {:error, %ImportError{field: :decision, reason: reason, data: nil}}
      end
    end
    def add_one(%{export: export} = context, field, add_proc) when is_atom(field) do
      Logger.debug("importing #{field}")

      case Map.fetch(export, Atom.to_string(field)) do
        {:ok, data} when is_map(data) ->
          case add_proc.(context, data) do
            {:ok, result} -> {:ok, %Context{context | fields: Map.put(context.fields, field, result)}}
            {:error, reason} -> {:error, %ImportError{field: field, reason: reason, data: data}}
          end

        _ ->
          {:ok, context}
      end
    end

    def add_many(%{export: export} = context, field, add_proc) when is_atom(field) do
      Logger.debug("importing #{field}")
      result = case Map.fetch(export, Atom.to_string(field)) do
        {:ok, data_list} when is_list(data_list) ->
          data_list
          |> Enum.filter(&(is_map(&1)))
          |> Enum.reduce_while(context, fn(data, context) ->
            case add_proc.(context, data) do
              {:ok, result} ->
                case Map.fetch(data, "id") do
                  {:ok, id} ->
                    field_map = context.fields |> Map.get(field, %{}) |> Map.put(id, result)
                    {:cont, %Context{context | fields: Map.put(context.fields, field, field_map)}}

                  :error ->
                    {:cont, context}
                end

              {:error, reason} ->
                {:halt, {:error, {reason, data}}}
            end
          end)

        _ ->
          context
      end

      case result do
        %Context{} = context ->
          {:ok, context}

        {:error, {reason, data}} ->
          {:error, %ImportError{field: field, reason: reason, data: data}}
      end
    end

    def take_ids(%Context{} = context, data, key_list) do
      Enum.reduce(key_list, %{}, fn({ctx_key, data_key}, acc) ->
        value = Map.get(context.fields, ctx_key, %{})
             |> Map.get(Map.get(data, Atom.to_string(data_key)), %{})
             |> Map.get(:id)

        case value do
          nil -> acc
          _   -> Map.put(acc, data_key, value)
        end
      end)
    end

    def take(%{} = map, keys) do
      Map.take(map, Enum.map(keys, &(Atom.to_string(&1))))
      |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)
      |> Map.new
    end
    def take(_, _) do
      {:error, :not_object}
    end

    def fetch(%{} = map, key) do
      case Map.fetch(map, key) do
        {:ok, value} -> {:ok, value}
        :error -> {:error, {:not_found, key}}
      end
    end
    def fetch(_, _) do
      {:error, :not_object}
    end

    def get(map, key, default \\ nil)
    def get(%{} = map, key, default) do
      Map.get(map, key, default)
    end
    def get(_, _, _) do
      {:error, :not_object}
    end


  end

end
