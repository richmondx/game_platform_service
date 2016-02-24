defmodule TcpConnectionSupervisor do
  @moduledoc """
  """
  use Supervisor
  require Logger
  def start_link() do
    supervisor_id = Kernel.abs(:erlang.unique_integer)
    {:ok, pid} = Supervisor.start_link(__MODULE__, :ok, [[name: generateName(supervisor_id)]])
    Process.register(pid, generateName(supervisor_id))
    {:ok, pid}
  end
  def generateName(unique_id) do
    String.to_atom("tcpconnection_supervisor_#{unique_id}" )
  end
  def init(:ok) do
    processor_stack_id = Kernel.abs(:erlang.unique_integer)
    tcp_listener_id = Kernel.abs(:erlang.unique_integer)
    children = [
      worker(TcpConnectionListener, [tcp_listener_id, processor_stack_id]),
    #  worker(TcpConnectionProcessorWorker, [tcp_listener_id, processor_stack_id])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
