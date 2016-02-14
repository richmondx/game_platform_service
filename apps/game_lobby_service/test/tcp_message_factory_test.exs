defmodule TcpMessageFactoryTest do
  @moduledoc """
  """
  use ExUnit.Case

  test "parse echo message" do
    test_message = <<0 :: size(8), 5 :: size(32)>><><<"hello">><><< 0 :: size(8)>>
    {:ok, msg,<<>>} = TcpMessageFactory.toTcpMessage(test_message)
    assert msg.message == "hello"
  end
end
