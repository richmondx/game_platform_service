defmodule RoutingServiceSupervisor do
  @moduledoc """
  """
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("routing_service_supervisor")
  end
  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: String.to_atom("routing_service_task_supervisor") ]]),
      supervisor(RoutingServiceTransactionPool, []),
      worker(RoutingServiceTransactionManager, []),
      worker(TransactionManagerRepo, []),
      worker(ConnectionRegisterRepo, []),
      worker(RoutingServiceConnectionRegister, []),
      worker(RoutingServiceRouter, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
