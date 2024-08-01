defmodule EtheloApi.Scenarios.ScenariosOptions do
  @moduledoc """
  many to many relation between Scenarios and Options
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EtheloApi.Scenarios.ScenariosOptions
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Structure.Option

  @primary_key false
  schema "scenarios_options" do
    belongs_to :scenario, Scenario
    belongs_to :option, Option
  end

  @doc """
  Prepares and Validates attributes for creating a ScenariosOptions record
  """
  def create_changeset(attrs) do
    %ScenariosOptions{}
    |> cast(attrs, [:scenario_id, :option_id])
    |> foreign_key_constraint(:scenario_id)
    |> foreign_key_constraint(:option_id)
  end
end
