defmodule TcpConnection do
  def start_link() do
    opts = [port: Application.get_env(:tcp_connection, :port)]
    {:ok, pid} = :ranch.start_listener(:tcpconnection, Application.get_env(:tcp_connection, :ranch_handler_count), :ranch_tcp, opts, TcpConnectionWorker, [])
    Process.register(pid, generateName())
    {:ok, pid}
  end
  def generateName() do
    String.to_atom("tcpconnection_listener" )
  end
end
