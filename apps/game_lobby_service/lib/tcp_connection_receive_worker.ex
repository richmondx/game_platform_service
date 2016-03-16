defmodule TcpConnectionReceiveWorker do
  use GenServer
  def start_link(processor_id, listener_id, socket, transport) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{processor_id: processor_id, listener_id: listener_id, socket: socket, transport: transport}, [])
    Process.register(pid, generateReceiverName(processor_id))
    zoo_keeper_client = GenServer.call(:zookeeper_client_worker, {:get_client})
    datapath = "/services/tcpconnection_receiver_worker/#{to_string(processor_id)}"
    {:ok, path} = Zookeeper.Client.create(zoo_keeper_client, datapath, generateRecordData(listener_id, processor_id))
    {:ok, pid}
  end
  def generateRecordData(listener_id, processor_id) do
    "tcpconnection_receiver_worker:#{processor_id},name:#{generateReceiverName(processor_id)},node:#{node()},listener_id:#{listener_id}"
  end
  defp generateReceiverName(processor_id) do
    String.to_atom("tcpconnection_receiver_worker_" <> Integer.to_string(processor_id))
  end
  def init(state) do
    {:ok, state}
  end
  def handle_cast({:send_tcp_message, msg}, state) do
    socket = Map.get(state, :socket)
    transport = Map.get(state, :transport)
    bin_response = TcpParserProtocol.to_bin?(msg)
    transport.send(socket, bin_response)
    {:noreply, state}
  end
  defp generateReceiverName(processor_id) do
    String.to_atom("tcpconnection_receiver_worker_" <> Integer.to_string(processor_id))
  end
end
