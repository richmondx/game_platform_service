defmodule RoutingServiceTransactionManager do
  @moduledoc """
  """
  require Logger
  def start_link() do
    service_pid = spawn_link(__MODULE__, :service_transaction, [[]])
    Process.register(service_pid, String.to_atom("routing_service_transaction") )
    {:ok, service_pid}
  end
  def init(state) do
    #ets_tbl = :ets.new(:pending_transactions, [:set, :protected])

    {:ok, %RoutingServiceTransactionManagerState{}}
  end
  defp worker_pool_name() do
    String.to_atom("routing_service_transaction_pool")
  end
  def service_transaction(queueList) do

    receive do

      {:queue_transaction, transactional_message, transactional_op, connection_id} ->

        service_transaction([ %{transactional_message: transactional_message, transactional_op: transactional_op, connection_id: connection_id} | queueList ])
      after
        5->
          for trans<-queueList do
            Task.Supervisor.start_child(:routing_service_task_supervisor, fn ->
              :poolboy.transaction(worker_pool_name(), fn(pid)->
                {:service, service} = GenServer.call(:routing_service_register_worker , {:get_service_by_op, Map.get(trans, :transactional_op)})
                GenServer.cast(pid, {:process_transaction, Map.get(trans, :transactional_message), service, Map.get(trans, :transactional_op), Map.get(trans, :connection_id)})
              # worker_delay()
              end)
            end)
          end

        #worker = :poolboy.checkout(worker_pool_name())
        service_transaction([])
      end

  end

  def worker_delay() do
    :timer.sleep(10)
  end

end
