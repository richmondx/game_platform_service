defmodule RoutingServiceTransactionPool do
  @moduledoc """
  """
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("routing_service_transaction_pool_supervisor")
  end
  def init(:ok) do
    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, RoutingServiceTransactionPoolWorker},
      {:size, 100},
      {:max_overflow, 0},
      {:strategy, :fifo}
    ]
    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
  defp pool_name() do
    String.to_atom("routing_service_transaction_pool")
  end
end
