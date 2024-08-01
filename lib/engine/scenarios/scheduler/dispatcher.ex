defmodule Engine.Scenarios.Dispatcher do
    @vsn 1
    use GenServer

    require OK

    alias Engine.Scenarios
    alias Engine.Scenarios.DispatcherJob
    alias Engine.Invocation

    defmodule State do
        defstruct state_by_id: %{},
                  state_by_job: %{}
    end

    defmodule DecisionState do
        defstruct id: nil,
                  job: nil,
                  started: nil,
                  touched: nil
    end

    def start_link(options \\ []) do
        GenServer.start_link(__MODULE__, %State{}, options |> Keyword.put(:name, Engine.Scenarios.Dispatcher))
    end

    def dispatch_solve(decision_id, options \\ []) do
        OK.for do
            scenario_config_id <- case Keyword.get(options, :scenario_config_id) do
                nil -> {:error, "missing scenario config id"}
                scenario_config_id -> {:ok, scenario_config_id}
            end
            scenario_config <- case Scenarios.get_scenario_config(scenario_config_id, decision_id) do
                nil -> {:error, "missing scenario config"}
                scenario_config -> {:ok, scenario_config}
            end

            scenario_set_or_pid <- cond do
                Keyword.get(options, :async, false) ->
                    GenServer.call(Engine.Scenarios.Dispatcher,
                        {:dispatch_now, decision_id, options})

                Keyword.get(options, :force, false) ->
                  Invocation.solve_decision(decision_id, options)

                scenario_config.solve_interval > 0 ->
                    GenServer.call(Engine.Scenarios.Dispatcher,
                        {:dispatch, {decision_id, scenario_config_id},
                                    {decision_id, options},
                                    scenario_config.solve_interval})

                true ->
                    Invocation.solve_decision(decision_id, options)
            end
        after
            scenario_set_or_pid
        end
    end

    def init(state) do
        Process.flag(:trap_exit, true)
        {:ok, state}
    end

    def handle_call({:dispatch, id, parameters, interval}, _from, state) do
        utc_now = DateTime.utc_now()
        decision_state = case Map.fetch(state.state_by_id, id) do
            {:ok, decision_state} ->
                DispatcherJob.touch(decision_state.job)
                %DecisionState{decision_state | touched: utc_now}

            :error ->
                {:ok, job} = DispatcherJob.start_link(parameters, interval)
                %DecisionState{id: id,
                               job: job,
                               started: utc_now,
                               touched: utc_now}
        end

        {:reply, {:ok, decision_state.job}, %State{state | state_by_id: Map.put(state.state_by_id, decision_state.id, decision_state),
                                                           state_by_job: Map.put(state.state_by_job, decision_state.job, decision_state)}}
    end

    def handle_call({:dispatch_now, decision_id, options}, _from, state) do
        {:ok, pid} = Task.start_link(fn ->
          Invocation.solve_decision(decision_id, options)
        end)
        {:reply, {:ok, pid}, state}
    end

    def handle_call(request, from, state) do
        super(request, from, state)
    end

    def handle_info({:EXIT, from, _reason}, state) do
        case Map.fetch(state.state_by_job, from) do
            {:ok, decision_state} ->
                {:noreply, %State{state | state_by_id: Map.delete(state.state_by_id, decision_state.id),
                                           state_by_job: Map.delete(state.state_by_job, decision_state.job)}}

            :error ->
                {:noreply, state}
        end
    end
    def handle_info(info, state) do
        super(info, state)
    end
end
