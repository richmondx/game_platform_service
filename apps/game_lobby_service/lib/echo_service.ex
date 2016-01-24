defmodule EchoService do
  require Logger
  def start_link() do
    pid = spawn_link(__MODULE__,:service_requests,[])
    Process.register( pid, :echo_service)
    {:ok, pid}
  end
  def service_requests() do
    receive do
      {:handle_msg, msg, recipient} ->
        resp = %TcpEchoMessageResponse{ message: msg.message}
        send recipient, {:send_tcp_message, resp}

    end
    service_requests()
  end

end
