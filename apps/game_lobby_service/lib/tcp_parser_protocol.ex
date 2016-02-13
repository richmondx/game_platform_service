defprotocol TcpParserProtocol do
  @doc "parse bytes into object y"
  def to_bin?( message_type )
end
defimpl TcpParserProtocol, for: TcpEchoMessageResponse do
    def to_bin?( message_type ) do
      b = byte_size(message_type.message)
      <<1>> <> <<b>> <> message_type.message <> <<0>>
    end
end
defimpl TcpParserProtocol, for: TcpAuthenticateSessionMessageResponse do
    def to_bin?( message_type ) do
        case message_type.authenticate_success do
            true->
            tokenLen = String.length(message_type.authenticate_token)
            <<3>> <> <<1>> <> <<tokenLen>> <> message_type.authenticate_token <> <<0>>
            false->
            messageLen = String.length(message_type.authenticate_message)
            <<3>> <> <<1>> <> <<0>> <> <<messageLen>> <> message_type.authenticate_message <> <<0>>
        end
    end
end
