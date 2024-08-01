defmodule Engine.Scenarios.ScenariosOptions.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key false
    end
  end
end

defmodule Engine.Scenarios.ScenariosOptions do

  use Engine.Scenarios.ScenariosOptions.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias Engine.Scenarios.ScenariosOptions
  alias Engine.Scenarios.Scenario
  alias EtheloApi.Structure.Option

  schema "scenarios_options" do
    belongs_to :scenario, Scenario
    belongs_to :option, Option
  end

  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required( [:scenario_id, :option_id])
  end

  def base_changeset(%ScenariosOptions{} = scenarios_options, attrs) do
    scenarios_options
    |> cast(attrs, [:scenario_id, :option_id])
  end

  def create_changeset(%ScenariosOptions{} = scenarios_options, attrs) do
    scenarios_options
    |> base_changeset(attrs)
    |> add_validations
  end

  def update_changeset(%ScenariosOptions{} = scenarios_options, attrs) do
    scenarios_options
    |> base_changeset(attrs)
    |> add_validations
  end
end
