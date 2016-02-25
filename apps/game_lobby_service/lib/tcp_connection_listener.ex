defmodule TcpConnectionListener do
  @moduledoc """
  """
  require Logger
  def start_link(listener_id, processor_id) do
    {:ok, pid, port} = start_ranch_listener(Application.get_env(:tcp_connection, :port), listener_id, processor_id)
    zoo_keeper_client = GenServer.call(:zookeeper_client_worker, {:get_client})
    datapath = "/services/tcpconnection_listener/#{to_string(listener_id)}"
    {:ok, path} = Zookeeper.Client.create(zoo_keeper_client, datapath, generateRecordData(port, listener_id))
    Process.register(pid, generateName(listener_id))
    {:ok, pid}
  end
  def generateRecordData(port, unique_id) do
    "port:#{port},name:#{generateName(unique_id)},node:#{node()}"
  end
  def generateName(unique_id) do
    String.to_atom("tcpconnection_listener_#{unique_id}" )
  end

  defp start_ranch_listener(start_http_port,  listener_id, processor_id) do
    opts = [port: start_http_port]
    #unique_id = Kernel.abs(:erlang.unique_integer)
    case :ranch.start_listener(:tcpconnection, Application.get_env(:tcp_connection, :ranch_handler_count), :ranch_tcp, opts, TcpConnectionProcessor, [listener_id, processor_id]) do
      {:ok, pid}->{:ok, pid, start_http_port}
      {:error, _}->start_ranch_listener( (start_http_port + 1), 1, 50,  listener_id, processor_id)
    end
  end
  defp start_ranch_listener(current_port, number_of_attempts, max_attempts,  listener_id, processor_id) do
    opts = [port: current_port]

    #unique_id = Kernel.abs(:erlang.unique_integer)
    case :ranch.start_listener(:tcpconnection, Application.get_env(:tcp_connection, :ranch_handler_count), :ranch_tcp, opts, TcpConnectionProcessor, [ listener_id, processor_id]) do
      {:ok, pid}->{:ok, pid, current_port}
      {:error, cause}->
        case number_of_attempts > max_attempts do
          true->{:error, cause}
          false->start_ranch_listener(current_port + 1, number_of_attempts + 1, 50,  listener_id, processor_id)
          other->start_ranch_listener(current_port + 1, number_of_attempts + 1, 50,  listener_id, processor_id)
        end
    end
  end
end
