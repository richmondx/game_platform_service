defmodule TcpMessageFactory do
  @moduledoc """
  """
  require Logger
  def toTcpMessage(bin) when is_binary(bin)  do
    case bin do
      <<0 ::size(8), sz::size(32), msg::binary-size(sz), remainder::binary>> ->
        build_echo_message(msg, remainder)
      <<2 ::size(8), princ_size::size(32), principal_name::binary-size(princ_size), pass_size::size(32), password::binary-size(pass_size), remain>> ->
        build_authenticate_session_message(principal_name, password, remain)
      other-> Logger.error "Unknown TcpMessageFactory.toTcpMessage #{inspect other}"
    end
  end

  defp build_echo_message(msg, remainder) do
    case remainder do
      <<0::size(8), next_message::binary>>->{:ok, %TcpEchoMessage{message: to_string(msg)}, next_message}
      <<0::size(8)>>->{:ok, %TcpEchoMessage{message: msg}, <<>>}
      0->{:ok, %TcpEchoMessage{message: msg}, <<>>}
      other-> Logger.error "Unknown echo msg #{inspect other}"
    end
  end
  defp build_authenticate_session_message(principal_name, pwd, remainder) do
    case remainder do
      <<0::size(8), next_message::binary>>->
        {:ok, %TcpAuthenticateSessionMessage{principal: principal_name, password: pwd}, next_message}
        <<0::size(8)>>->{:ok, %TcpAuthenticateSessionMessage{principal: principal_name, password: pwd}, <<>>}
      0->{:ok, %TcpAuthenticateSessionMessage{principal: principal_name, password: pwd}, <<>>}
      other->Logger.error "Unknown authenticate_session_message #{inspect other}"
    end
  end

end
