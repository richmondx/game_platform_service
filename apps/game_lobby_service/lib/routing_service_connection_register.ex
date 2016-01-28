defmodule RoutingServiceConnectionRegister do
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %RoutingServiceRegisterState{}, [])
    Process.register(pid, String.to_atom("routing_service_register_worker") )
    serviceListener = spawn_link(__MODULE__, :service_register, [])
    Process.register(serviceListener, String.to_atom("routing_service_register"))
    {:ok, pid}
  end
  def init(state) do
    Logger.info "init"
    {:ok, state}
  end
  def service_register() do
    Logger.info "starting loop"
    service_loop()
  end
  defp service_loop() do
    receive do
      {:add_client, connection_id, responder_pid} ->
        client_list_update = %ClientRoute{  client_id: connection_id, client_responder_pid: responder_pid }
        GenServer.cast( :routing_service_register_worker , {:add_client, client_list_update} )
      {:add_service, service_type, service_entry_pid, service_operations} ->
        service_list_update = %ServiceRoute{ service_type: service_type, service_entry_pid: service_entry_pid,  service_operations: service_operations }
        GenServer.cast(:routing_service_register_worker, {:add_service, service_list_update})
      {:route_message, message, connection_id} ->
        GenServer.cast(:routing_service_register_worker, {:build_route, message, connection_id})
    end
    service_loop()
  end
  def handle_call( {:get_service_by_op, service_op}, _from, state) do
    {:reply, List.foldl(state.registered_servers, {:no_service}, fn ele, acc ->
      case acc do
        {:no_service} ->
          case List.foldl(ele.service_operations, false, fn e, a->
            case a do
              true->true
              false-> e == service_op.service_operation
            end
      end) do
        true->{:service, ele}
        false->acc
      end
      other->other
    end
  end), state}
  end
  def handle_call( {:get_client_by_connection_id, connection_id}, _from, state) do
    {:reply, List.foldl(state.registered_clients, {:no_client}, fn ele, acc ->
      case acc do
        {client, c}->{client,c}
        {no_client}->
          case ele.client_id == connection_id do
            true-> {:client, ele}
            false-> acc
          end
      end
    end), state }
  end
  def handle_cast( {:add_client, route}, state) do
    Process.monitor(route.client_responder_pid)
    {:noreply, RoutingServiceRegisterState.add_client(state, route)}
  end
  def handle_cast( {:add_service, route}, state ) do
    Process.monitor(route.service_entry_pid)
    {:noreply, RoutingServiceRegisterState.add_service(state, route) }
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {:noreply, RoutingServiceRegisterState.remove_pid(state, pid)}
  end
end
