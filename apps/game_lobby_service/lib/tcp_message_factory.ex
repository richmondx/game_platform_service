defmodule TcpMessageFactory do
  require Logger
  def toTcpMessage(bin) when is_binary(bin)  do
    case bin do
      <<id ::size(8), data::binary>>->
        case id do
          0->
            case data do
              <<sz::size(32), msg::binary>> ->
                case msg do
                  <<echo_message::binary-size(sz), remainder::binary>> ->
                    case remainder do
                      <<0::size(8), next_message::binary>>->
                        {:ok, %TcpEchoMessage{message: to_string(echo_message)}, next_message}
                        <<0::size(8)>>->{:ok, %TcpEchoMessage{message: msg}, <<>>}
                    end
                  <<echo_message::binary>> ->
                    {:continued, echo_message}
                end
            end
        end
    end
  end
end
