defmodule Engine.Driver.Node do
    @vsn 1
    use GenServer

    defmodule State do
        defstruct dispatcher: nil,
                  pools: %{},
                  messenger: nil
    end

    def start_link(config \\ [], options \\ []) do
        state = %State{dispatcher: Keyword.fetch!(config, :dispatcher),
                       pools: Keyword.fetch!(config, :pools)}
        GenServer.start_link(__MODULE__, state, options)
    end

    def call(node, function, arguments \\ {}, options \\ [])
    def call(node, function, arguments, options) when is_atom(function) and is_tuple(arguments) do
        GenServer.call(node, {:call, function, arguments, options}, Keyword.get(options, :timeout, :infinity))
    end
    def call(node, function, arguments, options) when is_atom(function) do
        call(node, function, {arguments}, options)
    end

    def init(state) do
        {:ok, state}
    end

    def handle_call({:call, function, arguments, options}, from, state) when is_atom(function) and is_tuple(arguments) do
        case Map.fetch(state.pools, Keyword.get(options, :pool, :default)) do
            {:ok, pool} ->
                timeout = Keyword.get(options, :timeout, :infinity)
                preemption_key = Keyword.get(options, :preemption_key, nil)
                Task.Supervisor.start_child(state.dispatcher, fn ->
                    if preemption_key != nil do
                      messenger = Engine.Driver.Messenger.start_link(preemption_key: preemption_key, caller: from, task_pid: self())
                      state = %{ state | messenger: messenger }
                    end
                    process_call({function, arguments, pool, timeout}, from)
                end)
                {:noreply, state}

            _ ->
                {:reply, {:error, :invalid_pool}, state}
        end
    end
    def handle_call(request, from, state) do
        super(request, from, state)
    end

    def handle_info(info, state) do
        super(info, state)
    end

    defp process_call({function, arguments, pool, timeout}, from) do
        :poolboy.transaction(pool, fn(engine) ->
            case Engine.Driver.Engine.call(engine, :version, {}, timeout) do
                {:ok, _version} ->
                    reply = Engine.Driver.Engine.call(engine, function, arguments, timeout)
                    GenServer.reply(from, reply)
                _ ->
                    process_call({function, arguments, pool, timeout}, from)
            end
        end, timeout)
    end
end
