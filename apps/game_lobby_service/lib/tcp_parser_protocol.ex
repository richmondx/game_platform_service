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
