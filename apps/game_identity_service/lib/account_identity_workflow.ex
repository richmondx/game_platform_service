defmodule AccountIdentityWorkflow do
  use GenServer
  import Ecto.Query
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, [])
    servicePid = spawn_link(__MODULE__,:account_identity_service,[])
    Process.register(pid, name())
    Process.register(servicePid, serviceName())
    {:ok, pid}
  end
  def name() do
    String.to_atom("account_identity_workflow_worker")
  end
  def serviceName() do
    String.to_atom("account_identity_workflow")
  end
  def init(state) do
    {:ok, %{}}
  end
  def account_identity_service do
    case Application.get_env(:account_identity_workflow, :initialize_database) do
      true->
        {:ok} =
          GenServer.call(:account_identity_workflow_worker, {:initialize_database})
          account_identity_service_loop()
      false->  account_identity_service_loop()
    end

  end
  defp account_identity_service_loop() do
    receive do
      {:create_account, email, name, pass, notifier} ->
        Task.Supervisor.start_child(:account_identity_task_supervisor, fn->
        account = %AccountIdentityModel{account_name: email, account_principal: name, account_password: pass}
        {:ok, created_account} = GenServer.call(:account_identity_workflow_worker, {:create_account, account})
        send(notifier, {:create_account_response, :ok, created_account})
      end)
    end
  end
  def handle_call({:create_account, account}, _from, state ) do
      userToCreate = Map.update!(account, :account_password, fn pwd->Aeacus.hashpwsalt(pwd) end)
      user = IdentityRepo.insert!(userToCreate)
      {:reply, {:ok, user}, state}
  end
  def handle_call({:initialize_database}, _from, state) do
    q = from m in AccountIdentityModel
    IdentityRepo.delete_all(q)
    {:reply, {:ok}, state}
  end
end
