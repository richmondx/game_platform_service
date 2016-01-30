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
    service_loop(0)
  end
  def service_loop(transaction_count) do
    if(transaction_count > 100) do
      GenServer.call(:echo_service_worker, {:flush_transactions_sync})
      service_loop(0)
    end
    receive do
      {:process_transaction, msg, transaction_id} ->
        resp = %TcpEchoMessageResponse{ message: msg.message}
        GenServer.cast(:echo_service_worker, {:add_transaction_response, resp, transaction_id})
        service_loop(transaction_count + 1)
      after
        50->
          GenServer.call(:echo_service_worker, {:flush_transactions_sync})
          service_loop(0)
    end
  end
  def handle_cast({:add_transaction_response, msg, transaction_id}, state) do
    {:noreply, [%QueuedTransactionResponse{message: msg, transaction_id: transaction_id} | state]}
  end
  def handle_call({:flush_transactions_sync}, _from, state) do
    for s <- state do
      send(:routing_service_transaction, {:fullfill_request_transaction, s.message, s.transaction_id} )
    end
    {:reply, :ok, []}
  end
  def handle_cast({:flush_transactions}, state) do
    for s <- state do

      send(:routing_service_transaction, {:fullfill_request_transaction, s.message, s.transaction_id} )
    end
    {:noreply, []}
  end
end
