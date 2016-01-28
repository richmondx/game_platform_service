defmodule RoutingServiceTransactionManager do
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %RoutingServiceTransactionManagerState{}, [])
    Process.register(pid, String.to_atom("routing_service_transaction_worker") )
    service_pid = spawn_link(__MODULE__, :service_transaction, [0, %{}])
    Process.register(service_pid, String.to_atom("routing_service_transaction") )
    {:ok, pid}
  end
  def init(state) do
    {:ok, state}
  end

  def service_transaction(responseQueCount, opcache) do
    if responseQueCount > 100 do
      Task.Supervisor.start_child(:routing_service_task_supervisor, fn ->
      GenServer.call(:routing_service_transaction_worker, {:flush_sync})
      end)
      service_transaction(0, opcache)
    end
    receive do
      {:fullfill_request_transaction, resp, transaction_id} ->
        Task.Supervisor.start_child(:routing_service_task_supervisor, fn ->
          GenServer.cast(:routing_service_transaction_worker, {:fullfill_transaction, resp, transaction_id})
        end)
        service_transaction(responseQueCount + 1, opcache)
      {:queue_transaction, transactional_message, transactional_op, connection_id} ->
        case Map.get(opcache, transactional_op) do
          n when n == nil->
                {:service, service} = GenServer.call(:routing_service_register_worker , {:get_service_by_op, transactional_op})
                GenServer.cast(:routing_service_transaction_worker, {:process_transaction, transactional_message, service, transactional_op, connection_id})
                service_transaction(responseQueCount,  Map.put(opcache, transactional_op, service ))
          service->
            GenServer.cast(:routing_service_transaction_worker, {:process_transaction, transactional_message, service, transactional_op, connection_id})
            service_transaction(responseQueCount,  opcache)
        end

      after
        20->
          GenServer.call(:routing_service_transaction_worker, {:flush_sync})
          service_transaction(0, opcache)
    end

  end
  def handle_call({:flush_sync}, _from, state) do
    for receipt<-state.active_transactions do
      service_route = receipt.transaction_service_route
      send service_route.service_entry_pid, {:process_transaction, receipt.transaction_message, receipt.transaction_id}
    end
    {:reply, :ok, Map.update!(Map.update!(state, :pending_transactions, fn l -> l ++ state.active_transactions

  end), :active_transactions, fn l-> [] end)}
  end
  def handle_cast({:fullfill_transaction, msg, transaction_id}, state) do
    {:transaction, t} = case Enum.filter(state.pending_transactions, fn t->
      t.transaction_id == transaction_id end) do
      []->
        {:no_transaction}
      [t]->
        {:transaction, t}
    end
    Task.Supervisor.start_child( :routing_service_task_supervisor , fn ->
      client = GenServer.call(:routing_service_register_worker, {:get_client_by_connection_id, t.connection_id})
      {name, c} = client
      send c.client_responder_pid, {:send_tcp_message, msg}
    end)
    {:noreply, state}
  end
  def handle_cast({:flush_queue}, state) do
    Task.Supervisor.start_child( :routing_service_task_supervisor , fn ->
      for receipt<-state.active_transactions do
        service_route = receipt.transaction_service_route
        send service_route.service_entry_pid, {:process_transaction, receipt.transaction_message, receipt.transaction_id}
      end
    end)
    {:noreply, Map.update!(Map.update!(state, :pending_transactions, fn l -> l ++ state.active_transactions

  end), :active_transactions, fn l-> [] end)}
  end
  def handle_cast( {:process_transaction, message, destination, operation, connection_id}, state ) do
    rec = %RoutingServiceTransactionReceipt{
        transaction_id: state.last_transaction_id + 1,
        request_message_id: message.header.message_id,
        request_time: :os.timestamp(),
        fullfillment_message_id: operation.fullfillment_message_id,
        connection_id: connection_id, transaction_service_route: destination, transaction_message: message}
    {:noreply, Map.update!(Map.update!(state, :active_transactions, fn l -> [rec | l]
      end), :last_transaction_id, fn i-> i+1 end) }
  end
end
