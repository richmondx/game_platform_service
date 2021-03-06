defmodule AccountIdentityServiceTest do
  @moduledoc """
  """
  use ExUnit.Case
  test "Create Account" do
    GenServer.call(:account_identity_workflow_worker, {:initialize_database})
      Process.send :account_identity_workflow, {:create_account, "accountName@here.com", "loginName", "password", self()}, []
      assert_receive({:create_account_response, :ok, account}, 2000)
  end
end
