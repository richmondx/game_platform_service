defmodule TcpMessageFactoryTest do
  use ExUnit.Case

  test "parse echo message" do
    testMessage = <<0 :: size(8), 5 :: size(32)>><><<"hello">><><< 0 :: size(8)>>
    {:ok, msg,<<>>} = TcpMessageFactory.toTcpMessage(testMessage)
    assert msg.message == "hello"
  end
end
