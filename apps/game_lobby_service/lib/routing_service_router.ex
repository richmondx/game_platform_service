defmodule RoutingServiceRouter do
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], [])
    servicePid = spawn_link(__MODULE__,:service_router,[])
    Process.register(pid, String.to_atom("routing_service_router_worker") )
    Process.register(servicePid, String.to_atom("routing_service_router"))
    {:ok, pid}
  end


  def service_router() do
    service_loop()
  end
  def service_loop() do
    receive do
      {:route_message, message, connection_id} ->
        service_op = RoutingServiceRouterOperationFactory.getOperationByMessageId(message.header.message_id)
        case service_op.transaction do
          true->
            send :routing_service_transaction, {:queue_transaction, message, service_op, connection_id }
        end
    end
    service_loop()
  end

end
