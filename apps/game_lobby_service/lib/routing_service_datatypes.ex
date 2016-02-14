defmodule ServiceRoute do
  @moduledoc """
  """
  defstruct [ service_type: :nop, service_entry_pid: nil, service_operations: [], service_id: -1]
end
defmodule ClientRoute do
  @moduledoc """
  """
  defstruct [ client_id: -1, client_responder_pid: nil]
end

defmodule RoutingServiceRoutingSendMessageRequest do
  @moduledoc """
  """
  defstruct [message: nil, destination_operation: :nop]
end

defmodule RoutingServiceRouterOperation do
  @moduledoc """
  """
  defstruct [message_id: -1, service_operation: :nop, transaction: false]
end
defmodule RoutingServiceRouterTransactionalOperation do
  @moduledoc """
  """
  defstruct [message_id: -1, service_operation: :nop, transaction: true, fullfillment_message_id: -1]
end
defmodule RoutingServiceRouterState do
  @moduledoc """
  """
  defstruct [send_message_queue: [], send_message_size: 0]
end
defmodule RoutingServiceTransactionPoolWorkerState do
  @moduledoc """
  """
      defstruct [active_transactions: [], last_transaction_id: 0]
end
defmodule RoutingServiceTransactionManagerState do
  @moduledoc """
  """
  defstruct [active_transactions: [], last_transaction_id: 0]
end
defmodule RoutingServiceTransactionReceipt do
  @moduledoc """
  """
  defstruct [transaction_id: -1, transaction_service_route: nil,  transaction_message: nil, connection_id: -1, request_message_id: -1, request_time: -1, fullfillment_message_id: -1, response_time: -1, transaction_ttl_ms: 1000 ]
end
defmodule RoutingServiceRouterOperationFactory do
  @moduledoc """
  """
  def getOperationByMessageId(message_id) do
    case message_id do
      0->
        %RoutingServiceRouterTransactionalOperation{
          message_id: 0,
          service_operation: :echo,
          transaction: true,
          fullfillment_message_id: 1
      }
      2->
        %RoutingServiceRouterTransactionalOperation{
          message_id: 2,
          service_operation: :authenticate_session,
          transaction: true,
          fullfillment_message_id: 3
        }
    end
  end
end
defmodule QueuedTransactionResponse do
  @moduledoc """
  """
  defstruct [message: nil, transaction_id: -1, response_pid: nil]
end
