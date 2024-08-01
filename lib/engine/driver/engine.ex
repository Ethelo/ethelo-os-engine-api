defmodule Engine.Driver.Engine do
    @vsn 1
    use GenServer
    require Logger


    defmodule State do
        defstruct driver: nil,
                  port: nil,
                  queue: []
    end

    def start_link(config \\ [], options \\ []) do
        # Fetch options
        driver = Application.get_env(:engine_driver, :pools, []),
        res = Keyword.get(config, :resolve, true)

        # Conditionally resolve driver path
        driver = if res do
            resolve(driver)
        else
            driver
        end

        GenServer.start_link(__MODULE__, %State{driver: driver}, options)
    end

    def call(engine, function, arguments \\ {}, timeout \\ :infinity)
    def call(engine, function, arguments, timeout) when is_atom(function) and is_tuple(arguments) do
        GenServer.call(engine, {:call, function, arguments}, timeout)
    end
    def call(engine, function, arguments, timeout) when is_atom(function) do
        call(engine, function, {arguments}, timeout)
    end

    def init(state) do
        Process.flag(:trap_exit, true)
        port = Port.open({:spawn, state.driver}, [{:packet, 4}, :binary, :nouse_stdio])
        {:ok, %{state | port: port}}
    end

    def terminate(reason, state) do
        # tear down the C++ process
        case Port.info(state.port, :os_pid) do
          {:os_pid, pid} ->
            System.cmd("kill", ["-9", "#{pid}"])
          _  ->
          Logger.debug("terminated without pid #{inspect reason}")

        end

        Enum.map(state.queue, fn(sender) ->
            GenServer.reply(sender, {:error, :engine_terminated})
        end)
    end

    def handle_call({:call, function, arguments}, from, state) when is_atom(function) and is_tuple(arguments) do
        send state.port, {self(), {:command, :erlang.term_to_binary({function, arguments})}}
        queue = state.queue ++ [from]
        {:noreply, %{state | queue: queue}}
    end
    def handle_call(request, from, state) do
        super(request, from, state)
    end

    def handle_info({port, {:data, data}}, state = %State{port: port}) do
        case state.queue do
            [] ->
                {:noreply, state}
            [sender | queue] ->
                GenServer.reply(sender, :erlang.binary_to_term(data))
                {:noreply, %{state | queue: queue}}
        end
    end
    def handle_info({:EXIT, port, _reason}, state = %State{port: port}) do
        {:stop, {:error, "engine terminated unexpectedly"}, state}
    end
    def handle_info(info, state) do
        super(info, state)
    end

    defp resolve(name, options \\ []) do
        # Fetch options
        safe = Keyword.get(options, :safe, true)

        # Resolve path to file
        path = Path.join([List.to_string(:code.priv_dir(:ethelo)), name])

        # Verify existence as necessary
        cond do
            !safe              -> path
            File.exists?(path) -> path
            true               -> raise "file not found: #{path}"
        end
    end
end
