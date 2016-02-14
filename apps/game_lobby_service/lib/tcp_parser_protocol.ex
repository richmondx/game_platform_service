defprotocol TcpParserProtocol do
  @doc """
  """

  def to_bin?( message_type )
end
defimpl TcpParserProtocol, for: TcpEchoMessageResponse do
  @doc """
  """
    def to_bin?( message_type ) do
      b = byte_size(message_type.message)
      <<1>> <> <<b>> <> message_type.message <> <<0>>
    end
end
defimpl TcpParserProtocol, for: TcpAuthenticateSessionMessageResponse do
  @doc """
  """
    def to_bin?( message_type ) do
        case message_type.authenticate_success do
            true->
            token_len = String.length(message_type.authenticate_token)
            <<3>> <> <<1>> <> <<token_len>> <> message_type.authenticate_token <> <<0>>
            false->
            message_len = String.length(message_type.authenticate_message)
            <<3>> <> <<1>> <> <<0>> <> <<message_len>> <> message_type.authenticate_message <> <<0>>
            other->
              message_len = String.length(message_type.authenticate_message)
              <<3>> <> <<1>> <> <<0>> <> <<message_len>> <> message_type.authenticate_message <> <<0>>
        end
    end
end
