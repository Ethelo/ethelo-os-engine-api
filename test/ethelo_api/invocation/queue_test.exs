defmodule EtheloApi.Invocation.QueueTest do
  @moduledoc false

  use EtheloApi.DataCase
  use Oban.Testing, repo: EtheloApi.Repo

  import EtheloApi.Structure.Factory
  import EtheloApi.Voting.Factory, only: [delete_participant: 1]

  alias EtheloApi.Invocation.SolveWorker
  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.Queue
  alias Oban.Job

  def setup_decision(with_voting \\ true, with_cache \\ true) do
    context = EtheloApi.Blueprints.SimpleDecision.build(with_voting)

    %{decision: decision, scenario_config: scenario_config} = context

    if with_cache do
      Invocation.update_decision_cache(decision)
      Invocation.update_scenario_config_cache(scenario_config, decision)
    end

    solve_options = %{
      "decision_id" => decision.id,
      "force" => false,
      "participant_id" => nil,
      "save_dump" => false,
      "scenario_config_id" => scenario_config.id,
      "use_cache" => false
    }

    context |> Map.put(:decision, decision) |> Map.put(:solve_options, solve_options)
  end

  def setup_decision_without_cache(), do: setup_decision(true, false)
  def setup_decision_without_voting(), do: setup_decision(false, true)

  test "Worker performs without error" do
    context = setup_decision()
    :ok = perform_job(SolveWorker, context.solve_options)
  end

  test "queues with group" do
    context = setup_decision()
    solve_options = context.solve_options

    {:ok, %Job{} = job} = Queue.queue_solve(context.decision, solve_options)

    unique_stamp = Map.get(job.args, :unique_stamp)
    assert {:error, _} = DateTime.from_iso8601(unique_stamp)

    assert_enqueued(worker: SolveWorker, args: %{unique_stamp: unique_stamp}, queue: :group)

    # duplicate fails
    {:ok, %Job{} = job} = Queue.queue_solve(context.decision, solve_options)
    assert true = job.conflict?

    compare = [worker: SolveWorker, args: %{unique_stamp: unique_stamp}, queue: :group]

    assert [_] = all_enqueued(compare)
  end

  test "queues with participant" do
    %{participants: %{one: participant}} = context = setup_decision()

    solve_options = context.solve_options |> Map.put("participant_id", participant.id)

    {:ok, %Job{} = job} = Queue.queue_solve(context.decision, solve_options)

    unique_stamp = Map.get(job.args, :unique_stamp)
    assert {:error, _} = DateTime.from_iso8601(unique_stamp)

    assert_enqueued(worker: SolveWorker, args: %{unique_stamp: unique_stamp}, queue: :personal)

    # duplicate fails
    {:ok, %Job{} = job} = Queue.queue_solve(context.decision, solve_options)
    assert true = job.conflict?

    compare = [worker: SolveWorker, args: %{unique_stamp: unique_stamp}, queue: :personal]

    assert [_] = all_enqueued(compare)
  end

  test "queues with force" do
    context = setup_decision()

    solve_options = context.solve_options |> Map.put("force", true)

    {:ok, %Job{} = job} = Queue.queue_solve(context.decision, solve_options)

    unique_stamp = Map.get(job.args, :unique_stamp)
    assert {:ok, _, _} = DateTime.from_iso8601(unique_stamp)

    assert_enqueued(worker: SolveWorker, args: %{unique_stamp: unique_stamp}, queue: :group)
  end

  test "invalid Decision returns error" do
    %{decision: decision} = context = setup_decision()
    delete_decision(decision)

    {:error, error} = Queue.queue_solve(decision, context.solve_options)

    assert :decision_id == error.field
    assert :not_found == error.code
    assert "does not exist" == error.message
  end

  test "invalid ScenarioConfig returns error" do
    %{scenario_config: scenario_config} = context = setup_decision()
    delete_scenario_config(scenario_config)

    {:error, error} = Queue.queue_solve(context.decision, context.solve_options)

    assert :scenario_config_id == error.field
    assert :not_found == error.code
    assert "does not exist" == error.message
  end

  test "invalid Participant returns error" do
    %{participants: %{one: participant}} = context = setup_decision()
    delete_participant(participant)

    solve_options = context.solve_options |> Map.put("participant_id", participant.id)

    {:error, error} = Queue.queue_solve(context.decision, solve_options)

    assert :participant_id == error.field
    assert :not_found == error.code
    assert "does not exist" == error.message
  end

  test "No Decision cache returns error" do
    context = setup_decision_without_cache()
    solve_options = context.solve_options |> Map.put("use_cache", true)

    {:error, error} = Queue.queue_solve(context.decision, solve_options)

    assert :use_cache == error.field
    assert :not_found == error.code
    assert "Decision cache does not exist" == error.message
  end

  test "No Scenario Config cache returns error" do
    context = setup_decision_without_cache()
    Invocation.update_decision_cache(context.decision)

    solve_options = context.solve_options |> Map.put("use_cache", true)

    {:error, error} = Queue.queue_solve(context.decision, solve_options)

    assert :use_cache == error.field
    assert :not_found == error.code
    assert "ScenarioConfig cache does not exist" == error.message
  end

  test "No Votes cache returns error" do
    context = setup_decision_without_voting()
    {:error, error} = Queue.queue_solve(context.decision, context.solve_options)

    assert :decision_id == error.field
    assert :votes == error.code
    assert "must have votes" == error.message
  end

  # test "we stay in the business of doing business" do
  #     :ok = Business.schedule_a_meeting(%{email: "monty@brewster.com"})

  #     assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :mailer)

  #     # Now, make an assertion about the email delivery
  #   end
end
