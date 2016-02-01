defmodule RoutingServiceTransactionPoolWorker do
  use GenServer
  require Logger
  def start_link([]) do
    {:ok, gen_server} = GenServer.start_link(__MODULE__, %RoutingServiceTransactionPoolWorkerState{}, [])
    pid = spawn_link(__MODULE__, :receiver, [gen_server] )
    {:ok, gen_server}
  end
  def init(state) do
    {:ok, state}
  end
  defp worker_pool_name() do
    String.to_atom("routing_service_transaction_pool")
  end
  def receiver(gen_server) do
    
    receiver_loop(gen_server)
  end
  defp receiver_loop(gen_server) do
    receive do
      {:fullfill_request_transaction, resp, transaction_id} ->
        GenServer.cast(gen_server, {:fullfill_transaction, resp, transaction_id})
        receiver_loop(gen_server)
      after
        5->
          GenServer.call(gen_server,{:flush_sync, self()})
          receiver_loop(gen_server)

    end
  end
  def handle_call({:flush_sync, response_pid}, _from, state) do

    Task.Supervisor.start_child(:routing_service_task_supervisor, fn ->
      for receipt<-state.active_transactions do
        service_route = receipt.transaction_service_route
        send service_route.service_entry_pid, {:process_transaction, receipt.transaction_message, receipt.transaction_id, response_pid}
      end
    end)
    for i<- state.active_transactions do
      insert_res = GenServer.cast(:routing_service_transaction_repo, {:insert, i}) #:ets.insert(state.pending_transactions, {"key_"<>Integer.to_string(i.transaction_id), Map.from_struct(i)})
    end
    {:reply, :ok, Map.update!(state, :active_transactions, fn l-> [] end)}
  end
  def handle_cast({:fullfill_transaction, msg, transaction_id}, state) do
    task = Task.Supervisor.async( :routing_service_task_supervisor , fn ->
    k = "key_"<>Integer.to_string(transaction_id)
    case GenServer.call(:routing_service_transaction_repo, {:get, transaction_id}) do
      [{^k, t}]->
        {:transaction, t}
      [] ->
        {:no_transaction}

    end
  end)
  {:transaction, t} = Task.await(task)
    Task.Supervisor.start_child( :routing_service_task_supervisor , fn ->
      client = GenServer.call(:routing_service_register_worker, {:get_client_by_connection_id, t.connection_id})
      {name, c} = client
      send c.client_responder_pid, {:send_tcp_message, msg}
      GenServer.cast(:routing_service_transaction_repo, {:remove, t})
    end)
    {:noreply, state}
  end
  def handle_cast({:flush_queue}, state) do
    for receipt<-state.active_transactions do
      service_route = receipt.transaction_service_route
      send service_route.service_entry_pid, {:process_transaction, receipt.transaction_message, receipt.transaction_id}
    end
    for i<- state.active_transactions do
      #:ets.insert(state.pending_transactions, {String.to_atom(Integer.to_string(i.transaction_id)), Map.from_struct(i)})
      GenServer.cast(:routing_service_transaction_repo, {:insert, i})
    end
    {:reply, :ok, Map.update!(state, :active_transactions, fn l-> [] end)}
  end
  def handle_cast( {:process_transaction, message, destination, operation, connection_id}, state ) do
    rec = %RoutingServiceTransactionReceipt{
        transaction_id: :erlang.unique_integer,
        request_message_id: message.header.message_id,
        request_time: :os.timestamp(),
        fullfillment_message_id: operation.fullfillment_message_id,
        connection_id: connection_id, transaction_service_route: destination, transaction_message: message}
    {:noreply, Map.update!(Map.update!(state, :active_transactions, fn l -> [rec | l]
      end), :last_transaction_id, fn i-> i+1 end) }
  end

end
