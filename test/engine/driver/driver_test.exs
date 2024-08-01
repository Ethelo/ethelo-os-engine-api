defmodule Engine.DriverTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Engine.Invocation
  alias Engine.Scenarios
  @moduletag timeout: 80000

  setup do
    # checkout a db connection (shared mode so it can be used by
    # the spawned processes)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EtheloApi.Repo, ownership_timeout: 80000)
    Ecto.Adapters.SQL.Sandbox.mode(EtheloApi.Repo, {:shared, self()})
  end

  test "engine link" do
    assert {:ok, _version} = Engine.Driver.call(:version)
  end

  test "a solve call executes" do
    invocation_jsons = generate_decision_for_solver()
    invocation_jsons = Map.put(invocation_jsons, :preprocessed, "")

    #IO.inspect( "solve start at #{DateTime.utc_now()}" )
    result  = solve(invocation_jsons)
    #IO.inspect( "solve end at #{DateTime.utc_now()}" )
    assert {:ok, _} = result
  end

  test "a preproc call executes" do
    files = generate_decision_for_solver()
    #IO.inspect( "preproc start at #{DateTime.utc_now()}" )
    result = preprocessed(files)
    #IO.inspect( "preproc end at #{DateTime.utc_now()}" )
    assert {:ok, _} = result
  end

  test "a solve call executes with preproc" do
    invocation_jsons = generate_decision_for_solver()
    #IO.inspect( "preproc start at #{DateTime.utc_now()}" )
    {:ok, preproc} = preprocessed(invocation_jsons)
    #IO.inspect( "preproc end at #{DateTime.utc_now()}" )
    invocation_jsons = Map.put(invocation_jsons, :preprocessed, preproc)
    #IO.inspect( "preproc solve start at #{DateTime.utc_now()}" )
    result  = solve(invocation_jsons)
    #IO.inspect( "preproc solve end at #{DateTime.utc_now()}" )
    assert {:ok, _} = result
  end

  test "an initial set of engine system processes are spun up even at rest (configured by Engine.Driver.pools.default.size)" do
    assert num_engine_system_processes() >= 8
  end

  describe "multiple solves in parallel" do
    setup context do
      starting_engine_process_count = num_engine_system_processes()
      [start_process_count: starting_engine_process_count]
    end

    test "a maximum number of engine system processes run at a time (configured by Engine.Driver.pools.default)", context do
      invocation_jsons = generate_decision_for_solver(20)
      spawn_solves(invocation_jsons, 30)
      assert num_engine_system_processes() - context[:start_process_count] <= 16
    end

    test "engine system processes tear down when the elixir processes exit", context do
      invocation_jsons = generate_decision_for_solver(20)
      spawn_solves(invocation_jsons, 12)
      cleanup_engine_processes()
      assert num_engine_system_processes() == context[:start_process_count]
    end

    test "engine system processes tear down when the elixir processes timeout", context do
      invocation_jsons = generate_decision_for_solver(20)

      # the timeout error will bubble to this process, so trap and hide the error output
      Process.flag(:trap_exit, true)
      capture_log(fn ->
        spawn_solves(invocation_jsons, 12, timeout: 100)
      end)
      Process.sleep(1000)
      assert num_engine_system_processes() == context[:start_process_count]
    end

    test "processes are pre-empted when using a pre-emption key", context do
      invocation_jsons = generate_decision_for_solver(20)

      # spawn both running and queued solves
      spawn_solves(invocation_jsons, 50, preemption_key: 'my_key', wait_between: 100)
      Process.sleep(5000)
      assert num_engine_system_processes() == context[:start_process_count]
    end
  end

  defp generate_invocation_jsons(decision_id) do
    scenario_config = Scenarios.list_scenario_configs(decision_id) |> List.first()
    options = [scenario_config_id: scenario_config.id]
    Invocation.invocation_jsons(decision_id, options)
  end

  defp generate_decision_for_solver(num_votes) do
      # create decision with lots of bin votes to the solver takes a long time to run
      %{decision: decision} = EtheloApi.Blueprints.PizzaProject.build(false)

      Enum.each(0..num_votes, fn(_) ->
        EtheloApi.Voting.Factory.create_bin_vote(decision)
      end)

      {:ok, files} = generate_invocation_jsons(decision.id)
      # timestamp = System.os_time(:second)

      files
  end

  defp generate_decision_for_solver do
    generate_decision_for_solver(1)
  end

  defp solve(data, options \\ []) do
    args = {data[:decision_json], data[:influents_json], data[:weights_json], data[:config_json], data[:preprocessed]}
    Engine.Driver.call(:solve, args, options)
  end

  defp preprocessed(%{decision_json: decision_json}) do
    Engine.Driver.call(:preproc, {decision_json})
  end

  defp spawn_solves(invocation_jsons, num, options \\ []) do
    wait_between = Keyword.get(options, :wait_between, 0)
    pids = Enum.map(0..num, fn(_) ->
      if wait_between > 0 do
        Process.sleep(wait_between)
      end
      spawn_link(fn ->
        _result = solve(invocation_jsons, options)
        #IO.inspect(result)
      end)
    end)

    # give the system processes time to spin up
    Process.sleep(1000)

    on_exit(fn ->
      # ensure we end each test with a clean slate of the engine processes killed
      cleanup(pids)
    end)

    pids
  end

  defp num_engine_system_processes do
    {num_processes, _} = System.cmd("/bin/sh", ["-c", "ps |grep ethelo_driver | wc -l"])
    {num, _} = Integer.parse(num_processes)
    num
  end

  defp cleanup(pids) do
    # kill any remaining engine calling processes
    if pids != nil do
      Enum.each(pids, fn(pid) ->
        Process.exit(pid, :kill)
      end)
    end

    cleanup_engine_processes()
  end

  defp cleanup_engine_processes() do
    # kill queued (and running) tasks in poolboy
    root_children = Supervisor.which_children(Engine.Driver.Supervisor)
    {_, task_sup_pid, _, _} = Enum.find(root_children, fn child -> match?({Task.Supervisor, _, _, _}, child) end)
    task_children = Supervisor.which_children(task_sup_pid)
    Enum.each(task_children, fn child ->
      {_, pid, _, _} = child
      Process.exit(pid, :kill)
    end)

    # wait for tear-down
    Process.sleep(1000)
  end
end
