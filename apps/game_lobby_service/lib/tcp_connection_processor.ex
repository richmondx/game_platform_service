defmodule TcpConnectionProcessor do
  require Logger
  def start_link(ref, socket, transport, opts) do
    {listener_id, processor_id} = {List.first(opts), List.last(opts)}
    Logger.info "listener pid"
    pid = spawn_link(__MODULE__, :init, [ref, socket, listener_id, processor_id, transport, opts])
    zoo_keeper_client = GenServer.call(:zookeeper_client_worker, {:get_client})
    datapath = "/services/tcpconnection_processor/#{to_string(processor_id)}"
    Logger.info "trying datapath for processor: #{datapath}"
    {:ok, path} = Zookeeper.Client.create(zoo_keeper_client, datapath, generateRecordData(listener_id, processor_id))
    Process.register(pid, generateName(processor_id) )
    {:ok, pid}
  end

  def generateRecordData(listener_id, processor_id) do
    "tcpconnection_listener:#{listener_id},name:#{generateName(processor_id)},node:#{node()}"
  end
  defp generateName(processor_id) do
    String.to_atom("tcpconnection_processor_" <> Integer.to_string(processor_id) )
  end
  defp generateWorkerName(processor_id) do
    String.to_atom("tcpconnection_processor_worker_" <> Integer.to_string(processor_id) )
  end
  defp generateReceiverName(processor_id) do
    String.to_atom("tcpconnection_receiver_worker_" <> Integer.to_string(processor_id))
  end
  def init(ref, socket, listener_id, processor_id, transport, opts) do
    :ok = :ranch.accept_ack(ref)
    Logger.info "ok"
    {listener_id, processor_id} = {List.first(opts), List.last(opts)}
    {:ok, worker_pid} = TcpConnectionProcessorWorker.start_link(processor_id, listener_id)
    {:ok, receiver_pid} = TcpConnectionProcessorWorker.start_link(processor_id, listener_id, socket)
    worker_name =  generateWorkerName(processor_id)
    receiver_name = generateReceiverName(processor_id)
    Process.register(worker_pid, worker_name)
    Process.register(receiver_pid, receiver_name) 
    Logger.info "start_link_processor: #{inspect worker_pid}, #{inspect worker_name}"
    transport.setopts(socket, [nodelay: :true])
    loop(socket, transport, processor_id, opts)
  end
  defp loop(socket, transport, connection_id,  opts) do
    {:ok, packet} = case transport.recv(socket, 0, 50) do
      {:ok, packet}->
        Logger.info "got packet #{inspect packet}"
        {:ok, packet}
      {:error, :timeout}->loop(socket, transport, connection_id, opts)
    end
    hacked_packet = case packet do
      "05hello"->
        <<0::size(8), 5::size(32)>> <> <<"hello">> <> <<0::size(8)>>
      other->other
    end
    GenServer.cast(generateWorkerName(List.last(opts)), {:process_packet, hacked_packet})
    loop(socket, transport, connection_id,  opts)
  end



end
