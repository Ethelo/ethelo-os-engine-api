defmodule EtheloApi.Graphql.Docs.Decision do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Decision, as: DecisionDocs
  alias EtheloApi.Graphql.QueryHelper

  def object_name() do
    "decision"
  end

  def input_fields() do
    [
      :copyable,
      :info,
      :internal,
      :keywords,
      :language,
      :max_users,
      :slug,
      :title
    ]
  end

  defp sample1() do
    Map.get(DecisionDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(DecisionDocs.examples(), "Sample 2")
  end

  defp update1() do
    Map.get(DecisionDocs.examples(), "Update 1")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.simple_query_example(
      "decisions",
      %{},
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Decisions"
    )
  end

  @spec get() :: String.t()
  def get() do
    QueryHelper.simple_query_example(
      "decision",
      %{id: 1},
      Map.keys(sample1()),
      [sample1(), sample2()],
      "Return matching Decision"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.simple_mutation_example(
      "createDecision",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add a Decosopm"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.simple_mutation_example(
      "updateDecision",
      params,
      Map.keys(update1()),
      update1(),
      "Update Decosopm"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])

    comment =
      "Delete a Decision.

    All associated data including Particpants, Voting and Scenario Sets will be permanently remove"

    QueryHelper.simple_delete_mutation_example(
      "deleteDecision",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end

  @spec import() :: String.t()
  def import() do
    attrs = Map.put(sample1(), :json_data, ~s|{"decision" => ...}|)

    params =
      QueryHelper.mutation_params(attrs, [:json_data, :title, :slug, :keywords, :language, :info])

    comment =
      "Import a Decision.

   Import Decision configuration from an export file."

    QueryHelper.simple_mutation_example(
      "importDecision",
      params,
      [:id],
      %{id: 300},
      comment
    )
  end

  @spec copy() :: String.t()
  def copy() do
    attrs = sample1() |> Map.put(:decision_id, 1)

    params =
      QueryHelper.mutation_params(attrs, [
        :decision_id,
        :title,
        :slug,
        :keywords,
        :language,
        :info
      ])

    comment =
      "Copy a Decision.

   Copy Decision configuration from an existing Decision. Participants and ScenarioSets are NOT copied"

    QueryHelper.simple_mutation_example(
      "copytDecision",
      params,
      [:id],
      %{id: 300},
      comment
    )
  end
end
