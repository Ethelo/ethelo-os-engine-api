defmodule EtheloApi.Constraints.SuggestionMatcher do
  @moduledoc """
  Given a list of suggested records, a list of existing records, and
  a function to check equality, add the id from a matched record to the
  suggested record.
  """

  def add_existing_ids(suggested, existing, matcher) do
    add_ids(suggested, existing, [], matcher)
  end

  defp add_ids([], _, checked_suggestions, _), do: checked_suggestions
  defp add_ids(suggested, [], checked_suggestions, _), do: checked_suggestions ++ suggested

  defp add_ids(suggested, existing, checked_suggestions, matcher) do
    [first | rest] = suggested
    {remaining_existing, checked_suggestions} = match_in(first, existing, [], checked_suggestions, matcher)
    add_ids(rest, remaining_existing, checked_suggestions, matcher)
  end

  defp match_in(suggested, [record], checked_records, checked_suggestions, matcher) do
    if matcher.(suggested, record) do
      {checked_records, add_matched_to_checked(suggested, record, checked_suggestions)}
    else
      {[record | checked_records], add_not_matched_to_checked(suggested, checked_suggestions)}
    end
  end

  defp match_in(suggested, existing, checked_records, checked_suggestions, matcher) do
    [record | remaining_existing] = existing
    if matcher.(suggested, record) do
      {remaining_existing ++ checked_records, add_matched_to_checked(suggested, record, checked_suggestions)}
    else
      match_in(suggested, remaining_existing, [record | checked_records], checked_suggestions, matcher)
    end
  end

  defp add_matched_to_checked(suggested, matched, checked_suggestions) do
    [suggested |> Map.put(:id, matched.id) | checked_suggestions]
  end

  defp add_not_matched_to_checked(suggested, checked_suggestions) do
    [suggested | checked_suggestions]
  end

end
