defmodule TcpMessageHeader do
  defstruct [message_id: 0]
end
defmodule TcpMessageData do
  defstruct [messageData: <<>>]
end
defmodule TcpMessage do
  defstruct [header: TcpMessageHeader, fields: [] ]
end
defmodule TcpEchoMessage do
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 0}, message: "" ]
end
defmodule TcpEchoMessageResponse do
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 1}, message: ""]
end
defmodule TcpAuthenticateSessionMessage do
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 2}, principal: "", password: ""]
end
defmodule TcpAuthenticateSessionMessageResponse do
  require TcpMessage
  defstruct [header: %TcpMessageHeader{message_id: 3}, authenticate_success: false, authenticate_message: "", authenticate_token: ""]
end
