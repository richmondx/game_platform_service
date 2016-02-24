defmodule TcpConnectionWorker do
  @moduledoc """
  """
  require Logger
  def start_link(ref, socket, transport, opts) do
    connection_id = List.first(opts)#:erlang.unique_integer
    pid = spawn_link(__MODULE__, :init, [ref, socket, connection_id, transport, opts])
    Process.register(pid, String.to_atom("tcpconnection_worker_" <> Integer.to_string(connection_id) ) )
    {:ok, pid}
  end

  def init(ref, socket, connection_id, transport, opts) do
    :ok = :ranch.accept_ack(ref)
    transport.setopts(socket, [nodelay: :true])
    responder_pid = spawn_link(__MODULE__, :responder_loop, [socket,  transport, [], 0])
    router_pid = spawn_link(__MODULE__, :router_loop, [[], [], responder_pid])
    parser_pid = spawn_link(__MODULE__, :parser_loop,[<<>>, [], 0, router_pid, connection_id])
    Process.register(responder_pid, String.to_atom("tcpconnection_worker_responder_"<>Integer.to_string(connection_id)) )
    Process.send :session_identity_workflow, {:create_session, connection_id, Node.self()}, []
    Process.register(router_pid, String.to_atom("tcpconnection_worker_router_"<>Integer.to_string(connection_id)) )
    Process.register(parser_pid, String.to_atom("tcpconnection_worker_parser_"<>Integer.to_string(connection_id)) )
    send String.to_atom("routing_service_register"), {:add_client, connection_id, responder_pid}
    Process.flag(:trap_exit, true)
    loop(socket, transport, connection_id, parser_pid, opts)
  end
  def responder_loop(socket,  transport, response_list, response_count) do
    if(response_count > Application.get_env(:tcp_connection_worker, :responder_force_flush_max)) do
      flush_responder(response_list, socket, transport)
      responder_loop(socket, transport, [], 0)
    end
    receive do
      {:send_tcp_message, tcp_message} ->
        bin_response = TcpParserProtocol.to_bin?(tcp_message)
        responder_loop(socket, transport, [bin_response | response_list], response_count + 1)
      after
        Application.get_env(:tcp_connection_worker, :responder_flush_delay)->
          flush_responder(response_list, socket, transport)
          responder_loop(socket, transport, [], 0)
    end
  end
  defp flush_responder(response_list, socket, transport) do
    for(resp<-response_list) do transport.send(socket, resp) end
  end
  def router_loop(items_to_route, route_list, responder_pid) do
    if(List.foldl(route_list, 0, fn _elem, acc -> (acc + 1) end ) > Application.get_env(:tcp_connection_worker, :router_force_flush_max)) do
      flush_router(route_list, responder_pid)
      router_loop(items_to_route, [], responder_pid)
    end
    receive do
      {:route_message, obj} ->
        msgs_to_route = [obj|items_to_route]
        processed_list = Enum.map(msgs_to_route, fn route_item->
          case route_item.header.message_id do
            0->
            {:echo_service, route_item}
          end
        end)
        router_loop([], processed_list, responder_pid)
      after
        Application.get_env(:tcp_connection_worker, :router_flush_delay)->
          flush_router(route_list, responder_pid)
          router_loop(items_to_route, [], responder_pid)
    end
  end

  defp flush_router(route_list, responder_pid) do
    for(item<-route_list) do
      case item do
        {dest, msg}->
          send dest, {:handle_msg, msg, responder_pid}
      end
    end
  end
  def parser_loop(bytes_to_parse, message_list, message_count, router_pid, connection_id) do
    if(message_count > Application.get_env(:tcp_connection_worker, :parser_force_flush_max)) do
      flushParser(message_list, router_pid, connection_id)
      parser_loop(bytes_to_parse, [], 0, router_pid, connection_id)
    end
    receive do
      {:parse_packet, packet} ->
        case TcpMessageFactory.toTcpMessage(bytes_to_parse<>packet) do
          {:ok, obj, extra_bytes} ->
            parser_loop(extra_bytes, [obj|message_list], message_count + 1, router_pid, connection_id)
          {:continued, msg}->
            parser_loop(msg, message_list, message_count, router_pid, connection_id)
        end
      after
        Application.get_env(:tcp_connection_worker, :parser_flush_delay)->
          flushParser(message_list, router_pid, connection_id)
          parser_loop(bytes_to_parse, [], 0, router_pid, connection_id)
    end
  end
  defp flushParser(message_list, router_pid, connection_id) do
    for( msg <- message_list ) do
      #send router_pid, {:route_message, msg}
      send :routing_service_router, {:route_message, msg, connection_id}
    end
  end
  defp loop(socket, transport, connection_id, parser_loop_ref, opts) do
    {:ok, packet} = case transport.recv(socket, 0, 50) do
      {:ok, packet}->{:ok, packet}
      {:error, :timeout}->loop(socket, transport, connection_id, parser_loop_ref, opts)
    end
    hacked_packet = case packet do
      "05hello"->
        <<0::size(8), 5::size(32)>> <> <<"hello">> <> <<0::size(8)>>
      other->other
    end
    send(parser_loop_ref, {:parse_packet, hacked_packet})
    loop(socket, transport, connection_id, parser_loop_ref, opts)
  end
end
