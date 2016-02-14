defmodule ConnectionRegisterRepo do
  @moduledoc """
  """
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__,  %{}, [])
    Process.register(pid, String.to_atom("routing_service_register_repo"))
    {:ok, pid}
  end
  def init(state) do
    client_ets = :ets.new(:client_registeration, [:set, :protected])
    service_ets = :ets.new(:service_registeration, [:set, :protected])
    op_ets = :ets.new(:operation_registeration, [:set, :protected])
    {:ok, %{client_repo: client_ets, service_repo: service_ets, op_repo: op_ets}}
  end
  def build_client_key(clientId) when is_integer(clientId) do
      "client_" <> Integer.to_string(clientId)
  end
  def build_client_key(clientRoute) do
      "client_" <> Integer.to_string(clientRoute.client_id)
  end
  def build_service_key(serviceId) when is_integer(serviceId) do
    "service"<>Integer.to_string(serviceId)
  end
  def build_service_key(serviceRoute) do
    "service_" <> Integer.to_string(serviceRoute.service_id)
  end

def handle_call({:get_service_by_op, service_op}, _from, state) do
  op_str = Atom.to_string(service_op.service_operation)
  service_id = case :ets.lookup(Map.get(state, :op_repo), op_str) do
    [{^op_str, service_list}]->{:ok, List.first(service_list)}
    other->{:not_found}
  end
  case service_id do
    {:ok, service_id}->
      service_key = case :ets.lookup(Map.get(state, :service_repo), service_id) do
        [{^service_id, service}]->{:service, service}
        other->{:no_service}
      end
      {:reply, service_key, state}
  end

end
def handle_call({:get_client_by_connection_id, connection_id}, _from, state) do
  client_key = build_client_key(connection_id)
  case :ets.lookup(Map.get(state, :client_repo), client_key) do
    [{^client_key, client}]->
      {:reply, {:client, client}, state}
    []->
      {:reply, {:no_client}, state}
  end

end

defp isClient(state, pid) do
  :ets.foldl(fn ({key, value}, acc)->
    case (value.client_responder_pid == pid) do
      true->{:true, value.client_id}
      case->acc
    end
  end, {:false}, Map.get(state, :client_repo))
end
defp getServiceId(state, pid) do
  :ets.foldl(fn ({key, value}, acc)->
    case (value.service_entry_pid == pid) do
      true->{:true, value.service_id}
      case->acc
    end
  end, {:false}, Map.get(state, :service_repo))
end
def handle_cast({:remove_pid, pid}, state) do
    case isClient(state, pid) do
      {:true, id}->
        send :session_identity_workflow, {:remove_session_by_connection_id, id}
        :ets.delete(Map.get(state, :client_repo), build_client_key(id))
      {:false}->
        service_id = case getServiceId(state, pid) do
          [service]->{:true, service.service_id}
          []->{:false}
        end
        case service_id do
          {:true, id}->:ets.delete(Map.get(state, :service_repo), build_service_key(id))
        end
    end
    {:noreply, state}
  end
  def handle_cast( {:add_service, route}, state ) do
    service_key = build_service_key(route)
    for op<-route.service_operations do
      operation_to_str = Atom.to_string(op)
      case :ets.lookup(Map.get(state, :op_repo), operation_to_str ) do
        [^operation_to_str, [services]]->:ets.insert(Map.get(state, :op_repo), {operation_to_str, [service_key|services]} )
        []->:ets.insert(Map.get(state, :op_repo), {operation_to_str, [service_key]})
      end
    end
    :ets.insert(Map.get(state, :service_repo), {service_key, route})
    {:noreply, state}
  end
  def handle_cast({:add_client, route}, state) do
    client_id = build_client_key(route)
    :ets.insert(Map.get(state, :client_repo) ,{client_id, route})
    {:noreply, state}
  end

end
