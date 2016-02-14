defmodule TcpMessageHeader do
  @moduledoc """
  """
  defstruct [message_id: 0]
end
defmodule TcpMessageData do
  @moduledoc """
  """
  defstruct [messageData: <<>>]
end
defmodule TcpMessage do
  @moduledoc """
  """
  defstruct [header: TcpMessageHeader, fields: [] ]
end
defmodule TcpEchoMessage do
  @moduledoc """
  """
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 0}, message: "" ]
end
defmodule TcpEchoMessageResponse do
  @moduledoc """
  """
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 1}, message: ""]
end
defmodule TcpAuthenticateSessionMessage do
  @moduledoc """
  """
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 2}, principal: "", password: ""]
end
defmodule TcpAuthenticateSessionMessageResponse do
  @moduledoc """
  """
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 3}, authenticate_success: false, authenticate_message: "", authenticate_token: ""]
end
