defmodule EtheloApi.Structure.TestHelper.DecisionHelper do
  @moduledoc """
  Decision specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      id: :string,
      title: :string,
      slug: :string,
      info: :string,
      keywords: :string,
      copyable: :boolean,
      max_users: :integer,
      language: :string,
      updated_at: :date,
      inserted_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :copyable,
      :info,
      :keywords,
      :language,
      :max_users,
      :slug,
      :title,
      :weighting
    ]
  end

  def empty_attrs() do
    %{
      influent_hash: nil,
      info: nil,
      keywords: [],
      language: nil,
      preview_decision_hash: nil,
      published_decision_hash: nil,
      slug: nil,
      title: nil,
      weighting_hash: nil
    }
  end

  def invalid_attrs() do
    %{
      copyable: "3",
      keywords: 6,
      language: "klingon",
      max_users: "fourty seven",
      public: 3,
      slug: "  ",
      title: ""
    }
  end

  def valid_attrs() do
    %{
      copyable: true,
      influent_hash: "C",
      info: "info",
      keywords: ["test", "foo", "bar"],
      language: :en,
      max_users: 19,
      preview_decision_hash: "B",
      published_decision_hash: "A",
      slug: "slug",
      title: "Title",
      weighting_hash: "D"
    }
  end

  def equivalent_fields() do
    [
      :copyable,
      :info,
      :keywords,
      :language,
      :make_users,
      :slug,
      :title
    ]
  end

  def assert_equivalent(expected, result) do
    assert expected.copyable == result.copyable
    assert expected.info == result.info
    assert expected.keywords == result.keywords
    assert expected.language == result.language
    assert expected.max_users == result.max_users
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.title == result.title
  end
end
