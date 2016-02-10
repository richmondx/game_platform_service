defmodule SessionIdentityServiceTest do
  use ExUnit.Case
  require Logger
  test "Create Session" do
    GenServer.call(:session_identity_workflow_worker, {:initialize_database})
    Process.send(:session_identity_workflow, {:create_session, :erlang.unique_integer, :some_node_name, self()}, [])
    assert_receive({:create_session_response, :ok, session}, 2000)
  end
  test "Remove Session" do
    GenServer.call(:session_identity_workflow_worker, {:initialize_database})
    id = :erlang.unique_integer
    Process.send(:session_identity_workflow, {:create_session, id, :some_node_name, self()}, [])
    assert_receive({:create_session_response, :ok, session}, 2000)
    Process.send(:session_identity_workflow, {:remove_session_by_connection_id, id, self()}, [])
    assert_receive({:remove_session_response, :ok}, 2000)
  end
  test "Authenticate Session" do
    GenServer.call(:account_identity_workflow_worker, {:initialize_database})
    GenServer.call(:session_identity_workflow_worker, {:initialize_database})
    id = :erlang.unique_integer
    Process.send(:account_identity_workflow, {:create_account, "accountName@here.com", "loginName", "password", self()}, [])
    assert_receive({:create_account_response, :ok, account}, 2000)
    Process.send(:session_identity_workflow, {:create_session, id, :some_node_name, self()}, [])
    assert_receive({:create_session_response, :ok, session}, 2000)
    msg = %TcpAuthenticateSessionMessage{principal: "loginName", password: "password"}
    Process.send(:session_identity_workflow, {:process_transaction, msg, 123123, self(), id }, [])
    assert_receive({:fullfill_request_transaction, response, id}, 2000)
  end
  test "Fail to authenticate session" do
    GenServer.call(:account_identity_workflow_worker, {:initialize_database})
    GenServer.call(:session_identity_workflow_worker, {:initialize_database})
    id = :erlang.unique_integer
    Process.send(:account_identity_workflow, {:create_account, "accountName@here.com", "loginName", "password", self()}, [])
    assert_receive({:create_account_response, :ok, account}, 2000)
    Process.send(:session_identity_workflow, {:create_session, id, :some_node_name, self()}, [])
    assert_receive({:create_session_response, :ok, session}, 2000)
    msg = %TcpAuthenticateSessionMessage{principal: "invalidLoginName", password: "invalidPassword"}
    Process.send(:session_identity_workflow, {:process_transaction, msg, 123123, self(), id }, [])
    assert_receive({:fullfill_request_transaction, response, id}, 2000)
  end
end
