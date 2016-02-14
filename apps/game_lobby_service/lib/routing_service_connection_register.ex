defmodule RoutingServiceConnectionRegister do
  @moduledoc """
  """
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], [])
    Process.register(pid, String.to_atom("routing_service_register_worker") )
    service_listener = spawn_link(__MODULE__, :service_register, [])
    Process.register(service_listener, String.to_atom("routing_service_register"))
    {:ok, pid}
  end
  def init(state) do
    Logger.info "init"
    {:ok, state}
  end
  def service_register() do
    Logger.info "starting loop"
    service_loop(0)
  end
  defp service_loop(last_service_id) do
    receive do
      {:add_client, connection_id, responder_pid} ->
        client_list_update = %ClientRoute{  client_id: connection_id, client_responder_pid: responder_pid }
        GenServer.cast( :routing_service_register_worker , {:add_client, client_list_update} )
        service_loop(last_service_id)
      {:add_service, service_type, service_entry_pid, service_operations} ->
        new_service_id = last_service_id + 1
        service_list_update = %ServiceRoute{ service_type: service_type, service_entry_pid: service_entry_pid,  service_operations: service_operations, service_id: new_service_id}
        GenServer.cast(:routing_service_register_worker, {:add_service, service_list_update})
        service_loop(new_service_id)
      {:route_message, message, connection_id} ->
        GenServer.cast(:routing_service_register_worker, {:build_route, message, connection_id})
        service_loop(last_service_id)
    end

  end
  def handle_call( {:get_service_by_op, service_op}, _from, state) do
    {:reply, GenServer.call(:routing_service_register_repo, {:get_service_by_op, service_op}), state}
  end
  def handle_call( {:get_client_by_connection_id, connection_id}, _from, state) do
    client = case GenServer.call(:routing_service_register_repo, {:get_client_by_connection_id, connection_id}) do
      {:client, c} ->{:client,c}
      other->{:noclient}
    end
    {:reply, client, state }
  end
  def handle_cast( {:add_client, route}, state) do

    Process.monitor(route.client_responder_pid)
    GenServer.cast(:routing_service_register_repo, {:add_client, route})

    {:noreply, state}
  end
  def handle_cast( {:add_service, route}, state ) do
    Task.Supervisor.start_child( :routing_service_task_supervisor , fn ->
    Process.monitor(route.service_entry_pid)
    GenServer.cast(:routing_service_register_repo, {:add_service, route})
  end)
    {:noreply, state }
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    Task.Supervisor.start_child( :routing_service_task_supervisor , fn ->
      GenServer.cast(:routing_service_register_repo, {:remove_pid, pid}) end)
    {:noreply, state}
  end
end
