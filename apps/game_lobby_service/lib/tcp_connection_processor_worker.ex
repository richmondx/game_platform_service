defmodule TcpConnectionProcessorWorker do
  use GenServer
  require Logger
  def start_link(processor_id, listener_id) do
    {:ok, server_pid} = GenServer.start_link(__MODULE__, %{listener_id: listener_id, processor_id: processor_id, bytes_to_parse: <<>>}, [])
    Process.register(server_pid, generateName(processor_id))
    {:ok, server_pid}
  end
  def generateName(id) do
    String.to_atom("tcpconnection_processor_worker_"<>Integer.to_string(id))
  end
  def init (state) do
    {:ok, state}
  end
  def handle_cast({:process_packet, packet}, state) do
    case parse_packet(Map.get(state, :bytes_to_parse) <> packet) do
      {:ok, msg, extra_bytes}->
        Logger.info "send msg #{inspect msg}"
        send :routing_service_router, {:route_message, msg, Map.get(state, :processor_id)}
        {:noreply, Map.update!(state, :bytes_to_parse, fn e-> extra_bytes end)}
      {:ok, msg}->
        Logger.info "send msg #{inspect msg}"
        send :routing_service_router, {:route_message, msg, Map.get(state, :processor_id)}
        {:noreply, Map.update!(state, :bytes_to_parse, fn e-> <<>> end)}
    end
  end
  defp parse_packet(packet) do
    case TcpMessageFactory.toTcpMessage(packet) do
      {:ok, msg, extra_bytes} -> {:ok, msg, extra_bytes}
      {:ok, msg}->{:ok, msg}
    end
  end
end
