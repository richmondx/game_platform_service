defmodule AccountIdentityWorkflow do
  @moduledoc """
  """
  use GenServer
  import Ecto.Query
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, [])
    service_pid = spawn_link(__MODULE__,:account_identity_service,[])
    Process.register(pid, name())
    Process.register(service_pid, serviceName())
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
      other-> account_identity_service_loop()
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
      account_identity_service_loop()
    end
  end
  def handle_call({:create_account, account}, _from, state ) do
      user_to_create = Map.update!(account, :account_password, fn pwd->Aeacus.hashpwsalt(pwd) end)
      user = IdentityRepo.insert!(user_to_create)
      {:reply, {:ok, user}, state}
  end

  def handle_call({:get_account_by_principal, principal}, _from, state) do
    user = IdentityRepo.get_by(AccountIdentityModel, principal: principal)
    {:reply, {:ok, user}, state}
  end
  def handle_call({:initialize_database}, _from, state) do
    q = from m in AccountIdentityModel
    IdentityRepo.delete_all(q)
    {:reply, {:ok}, state}
  end
  def handle_cast({:remove_session_id, session_id}, state) do
    case IdentityRepo.get_by(AccountIdentityModel, login_session: session_id) do
      nil -> nil
      account ->
        update_account = Ecto.Changeset.change account, login_session: ""
        IdentityRepo.update update_account
    end

    {:noreply, state}
  end
  def handle_cast({:set_login_session, session_id, account}, state) do
    update_account = Ecto.Changeset.change account, login_session: session_id
    IdentityRepo.update update_account
    {:noreply,  state}
  end
end
