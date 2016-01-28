defmodule EchoServiceProcessor do
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], [])
    Process.register(pid, String.to_atom("echo_service_worker") )
    requestPid = spawn_link(__MODULE__,:service_requests,[])
    Process.register(requestPid, String.to_atom("echo_service") )
    send(String.to_atom("routing_service_register"), {:add_service, :echo, requestPid, [:echo] })
    {:ok, pid}
  end
  def init([]) do
    {:ok, []}
  end
  def service_requests() do
    service_loop()
  end
  def service_loop() do
    receive do
      {:process_transaction, msg, transaction_id} ->
        resp = %TcpEchoMessageResponse{ message: msg.message}
        GenServer.cast(:echo_service_worker, {:add_transaction_response, resp, transaction_id})
        service_loop()
      after
        5->
          GenServer.cast(:echo_service_worker, {:flush_transactions})
          service_loop()
    end
  end
  def handle_cast({:add_transaction_response, msg, transaction_id}, state) do
    {:noreply, [%QueuedTransactionResponse{message: msg, transaction_id: transaction_id} | state]}
  end
  def handle_cast({:flush_transactions}, state) do
    for s <- state do
      send(:routing_service_transaction, {:fullfill_request_transaction, s.message, s.transaction_id} )
    end
    {:noreply, []}
  end
end
