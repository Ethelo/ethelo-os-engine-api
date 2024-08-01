defmodule Engine.Invocation.DecisionMapLoader do
  @moduledoc """
  Loads only required fields as maps instead of structures to save memory
  """
  alias EtheloApi.Repo
  import Ecto.Query

  def criteria_data(decision_id) do
    EtheloApi.Structure.Criteria
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [:id, :slug, :apply_participant_weights, :weighting, :deleted, :decision_id]))
    |> Repo.all
  end

  def option_data(decision_id) do
    EtheloApi.Structure.Option
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [:id, :slug, :enabled, :determinative,
      :deleted, :option_category_id, :decision_id]))
    |> Repo.all
  end

  def option_detail_value_data(decision_id) do
    EtheloApi.Structure.OptionDetailValue
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [:value, :option_id, :option_detail_id, :decision_id]))
    |> Repo.all
  end

  def option_detail_data(decision_id) do
    EtheloApi.Structure.OptionDetail
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [:id, :slug, :format, :title, :decision_id]))
    |> Repo.all
  end

  def option_category_data(decision_id) do
    EtheloApi.Structure.OptionCategory
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [
      :id, :slug, :title, :decision_id, :deleted, :xor, :quadratic,
      :scoring_mode, :apply_participant_weights, :weighting, :triangle_base,
      :primary_detail_id
      ]))
    |> Repo.all
  end

  def option_filter_data(decision_id) do
    EtheloApi.Structure.OptionFilter
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [
      :id, :slug, :title, :match_mode, :match_value,
      :option_category_id, :option_detail_id, :decision_id
      ]))
    |> Repo.all
  end

  def variable_data(decision_id) do
    EtheloApi.Structure.Variable
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [
      :id, :slug, :method,
      :option_filter_id, :option_detail_id, :decision_id
      ]))
    |> Repo.all
  end

  def calculation_data(decision_id) do
    EtheloApi.Structure.Calculation
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [:id, :slug, :expression, :public, :decision_id]))
    |> Repo.all
  end

  def constraint_data(decision_id) do
    EtheloApi.Structure.Constraint
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, [
      :id, :slug, :operator, :lhs, :rhs, :enabled, :relaxable,
      :variable_id, :calculation_id, :option_filter_id, :decision_id
      ]))
    |> Repo.all
  end

  # there aren't a lot of these but there are a lot of fields so load it all
  def scenario_config_data(decision_id) do
    Engine.Scenarios.ScenarioConfig
    |> where([s], s.decision_id == ^decision_id)
    |> Repo.all
  end

  def bin_vote_data(decision_id, participant_id \\ nil) do
    query = EtheloApi.Voting.BinVote
    |> select([s], map(s, [:option_id, :criteria_id, :bin, :participant_id, :decision_id]))
    |> where([s], s.decision_id == ^decision_id)

    query = if is_nil(participant_id) do
      query
    else
      query |> where([s], s.participant_id == ^participant_id)
    end

    query |> Repo.all
  end

  def option_category_weight_data(decision_id, participant_id \\ nil) do
    query = EtheloApi.Voting.OptionCategoryWeight
    |> select([s], map(s, [:option_category_id, :weighting, :participant_id, :decision_id]))
    |> where([s], s.decision_id == ^decision_id)

    query = if is_nil(participant_id) do
      query
    else
      query |> where([s], s.participant_id == ^participant_id)
    end

    query |> Repo.all
  end

  def criteria_weight_data(decision_id, participant_id \\ nil) do
    query = EtheloApi.Voting.CriteriaWeight
    |> select([s], map(s, [:criteria_id, :weighting, :participant_id, :decision_id]))
    |> where([s], s.decision_id == ^decision_id)

    query = if is_nil(participant_id) do
      query
    else
      query |> where([s], s.participant_id == ^participant_id)
    end

    query |> Repo.all
  end

  def option_category_range_vote_data(decision_id, participant_id \\ nil) do
    query = EtheloApi.Voting.OptionCategoryRangeVote
    |> select([s], map(s, [:option_category_id, :high_option_id, :low_option_id, :participant_id, :decision_id]))
    |> where([s], s.decision_id == ^decision_id)

    query = if is_nil(participant_id) do
      query
    else
      query |> where([s], s.participant_id == ^participant_id)
    end

    query |> Repo.all
  end

  def participant_data(decision_id, participant_id \\ nil) do
    query = EtheloApi.Voting.Participant
    |> select([s], map(s, [:id, :weighting, :decision_id]))
    |> where([s], s.decision_id == ^decision_id)

    query = if is_nil(participant_id) do
      query
    else
      query |> where([s], s.participant_id == ^participant_id)
    end

    query |> Repo.all
  end

end
