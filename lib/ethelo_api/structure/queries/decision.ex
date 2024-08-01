defmodule EtheloApi.Structure.Queries.Decision do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:slug, :id]
  end

  def match_query(modifiers \\ %{}) do
    keywords = Map.get(modifiers, :keywords, nil)
    modifiers = modifiers |> Map.delete(:keywords)

    query = Decision |> filter_query(modifiers, valid_filters())

    query =
      if keywords == nil || keywords == [] do
        query
      else
        query |> where([q], fragment("keywords::jsonb \\?| ?", ^keywords))
      end

    query
  end

  @doc """
  Returns the list of Options for a Decision.

  ## Examples

      iex> list_options(decision_id)
      [%Option{}, ...]

  """
  def list_decisions(modifiers \\ %{}) do
    match_query(modifiers)
    |> Repo.all()
  end

  @doc """
  Gets a single Decision.

  returns nil if Decision does not exist

  ## Examples

      iex> get_decision(123)
      %Decision{}

      iex> get_decision(456)
      nil

  """
  def get_decision(id) do
    Decision |> Repo.get(id) |> Repo.preload(:criterias)
  end

  @doc """
  Gets a single Decision matching the supplied modifiers

  returns nil if no matching Decisions exist

  ## Examples

      iex> match_decision(%{slug: "foo"})
      %Decision{}

      iex> match_decision(%{id: 299})
      nil

  """
  def match_decision(%{} = modifiers) do
    match_query(modifiers)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a Decision.

  ## Examples

      iex> create_decision(%{title: "This is my title"})
      {:ok, %Decision{}}

      iex> create_decision(%{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_decision(attrs \\ %{}) do
    attrs
    |> Decision.create_changeset()
    |> Repo.insert()
    |> ensure_default_associations()
  end

  def ensure_default_associations({:ok, %Decision{} = decision}),
    do: ensure_default_associations(decision)

  def ensure_default_associations(%Decision{} = decision) do
    EtheloApi.Structure.Queries.OptionFilter.ensure_all_options_filter(decision)
    EtheloApi.Structure.Queries.OptionCategory.ensure_default_option_category(decision)
    EtheloApi.Structure.Queries.Criteria.ensure_one_criteria(decision)
    EtheloApi.Structure.Queries.ScenarioConfig.ensure_one_scenario_config(decision)
    {:ok, decision}
  end

  def ensure_default_associations(value), do: value

  defp current_time_hash(), do: DateTime.utc_now() |> DateTime.to_iso8601()

  def update_decision_hash(decision_id) when is_integer(decision_id) do
    get_decision(decision_id) |> update_decision_hash()
  end

  def update_decision_hash(%Decision{} = decision) do
    Ecto.Changeset.change(decision, %{preview_decision_hash: current_time_hash()})
    |> Repo.update()
  end

  def update_decision_influent_hash(decision)

  def update_decision_influent_hash(%Decision{} = decision) do
    {:ok, hash} = EtheloApi.Invocation.generate_group_influent_hash(decision)

    Ecto.Changeset.change(decision, %{influent_hash: hash})
    |> Repo.update()
  end

  def update_decision_influent_hash(decision_id) when is_integer(decision_id) do
    get_decision(decision_id) |> update_decision_influent_hash()
  end

  @doc """
  Updates a Decision.

  ## Examples

      iex> update_decision(decision, %{field: new_value})
      {:ok, %Decision{}}

      iex> update_decision(decision, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_decision(decision_id, attrs) when is_integer(decision_id) do
    decision_id |> get_decision() |> update_decision(attrs)
  end

  def update_decision(%Decision{} = decision, attrs) do
    decision
    |> Decision.update_changeset(attrs)
    |> Repo.update()
  end

  def update_decision(nil, _) do
    {:error, "does not exist"}
  end

  @doc """
  Deletes a Decision.

  ## Examples

      iex> delete_decision(decision)
      {:ok, %Decision{}}

      iex> delete_decision(decision)
      {:error, %Ecto.Changeset{}}

  """
  def delete_decision(decision_id) when is_integer(decision_id) do
    decision_id |> get_decision() |> delete_decision()
  end

  def delete_decision(nil) do
    {:ok, nil}
  end

  def delete_decision(%Decision{} = decision) do
    Repo.delete(decision)
  end
end
