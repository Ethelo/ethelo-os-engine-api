defmodule Engine.Scenarios.DispatcherJob do
    @vsn 1
    use GenServer

    alias Engine.Invocation.ScenarioSolve

    defmodule State do
        defstruct parameters: nil,
                  interval: nil,
                  dirty: false,
                  skip: false,
                  worker: nil
    end

    def start_link(parameters, interval, options \\ []) do
        GenServer.start_link(__MODULE__, %State{parameters: parameters, interval: interval}, options)
    end

    def touch(dispatcher_job) do
        GenServer.cast(dispatcher_job, :dirty)
    end

    def init(state) do
        parent = self()
        worker = Task.start_link(fn -> dispatcher_worker(parent, state) end)
        {:ok, %State{state | worker: worker}}
    end

    def handle_cast(:dirty, state) do
        {:noreply, %State{state | dirty: true}}
    end
    def handle_cast(:cycle, state) do
        if state.dirty do
            parent = self()
            worker = Task.start_link(fn -> dispatcher_worker(parent, state) end)
            {:noreply, %State{state | dirty: false, worker: worker}}
        else
            {:stop, :normal, state}
        end
    end
    def handle_cast(request, state) do
        super(request, state)
    end

    def handle_info(info, state) do
        super(info, state)
    end

    defp dispatcher_worker(parent, %State{parameters: {decision_id, options}, interval: interval}) do
        # calling through invocation silently fails, call directly
        ScenarioSolve.solve_decision(decision_id, options)
        Process.sleep(interval)
        GenServer.cast(parent, :cycle)
    end
end
