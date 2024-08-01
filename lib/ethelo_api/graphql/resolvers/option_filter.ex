defmodule EtheloApi.Graphql.Resolvers.OptionFilter do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionFilters

  See `EtheloApi.Structure.list_option_filters/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_option_filters(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Creates a new OptionFilter

  See `EtheloApi.Structure.create_option_filter/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_option_filter(attrs, decision)
  end

  @doc """
  Updates an OptionFilter.

  See `EtheloApi.Structure.update_option_filter/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_option_filter(id, decision) do
      nil -> {:ok, not_found_error()}
      option_filter -> Structure.update_option_filter(option_filter, attrs)
    end
  end

  @doc """
  Deletes an OptionFilter.

  See `EtheloApi.Structure.delete_option_filter/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_option_filter(id, decision)
  end

  def datasource() do
    Dataloader.KV.new(&batch_query/2)
  end

  # returned keys must be the OptionFilters passed in, not the OptionFilter ids
  defp batch_query({:options_by_filter, %{decision_id: decision_id}}, option_filters) do
    option_filter_ids = Enum.map(option_filters, & &1.id)

    options_by_filter_ids = Structure.options_by_filter_ids(decision_id, option_filter_ids)

    option_filters
    |> Map.new(fn option_filter ->
      {option_filter, Map.get(options_by_filter_ids, option_filter.id)}
    end)
  end

  # returned keys must be the OptionFilters passed in, not the OptonFilter ids
  defp batch_query({:option_ids_by_filter, %{decision_id: decision_id}}, option_filters) do
    option_filter_ids = Enum.map(option_filters, & &1.id)

    %{ids: option_ids_by_filter} =
      Structure.option_ids_by_filter_ids(decision_id, option_filter_ids)

    option_filters
    |> Map.new(fn option_filter ->
      {option_filter, Map.get(option_ids_by_filter, option_filter.id)}
    end)
  end

  defp batch_query({_field_identifier, _field_args}, _args) do
    %{}
  end
end
