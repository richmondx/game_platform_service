defmodule SessionIdentityWorkflow do
  use GenServer
  import Ecto.Query
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, [])
    Process.register(pid, name())
    servicePid = spawn_link(__MODULE__,:workflow_service,[])
    send(String.to_atom("routing_service_register"), {:add_service, :session_identity, servicePid, [:authenticate_session] })
    Process.register(servicePid, serviceName())
    {:ok, pid}
  end
  def init(%{}) do
    {:ok, %{}}
  end
  def name() do
    String.to_atom("session_identity_workflow_worker")
  end
  def serviceName() do
    String.to_atom("session_identity_workflow")
  end
  def workflow_service() do
    case Application.get_env(:session_identity_workflow, :initialize_database) do
      true->
        {:ok} =
          GenServer.call(:session_identity_workflow_worker, {:initialize_database})
          workflow_service_loop()
      false->  workflow_service_loop()
    end

  end
  defp workflow_service_loop() do
    receive do
      {:process_transaction, msg, transaction_id, response_pid, connection_id} ->
        case msg.header.message_id do
          2->
            #tcp authenticate request
            Task.Supervisor.start_child(:session_identity_task_supervisor, fn->
              case GenServer.call(:session_identity_workflow_worker, {:authenticate, msg.principal, msg.password}) do
                {:authenticate_success, user}->
                  { :ok, jwt, full_claims } = Guardian.encode_and_sign(user, :token)
                  {:ok, session} = GenServer.call(:session_identity_workflow_worker, {:get_session_by_connection_id, connection_id})
                  GenServer.cast(:session_identity_workflow_worker, {:set_account, session, user.id})
                  GenServer.cast(:account_identity_workflow_worker, {:set_login_session, session.id, user})
                  resp = %TcpAuthenticateSessionMessageResponse{authenticate_success: true, authenticate_token: jwt}
                  send response_pid, {:fullfill_request_transaction, resp, transaction_id}
                {:authenticate_failure, msg}->
                  resp = %TcpAuthenticateSessionMessageResponse{authenticate_success: false, authenticate_message: msg}
                  send response_pid, {:fullfill_request_transaction, resp, transaction_id}
                end
            end)
        end
        workflow_service_loop()
      {:create_session, connection_id, connection_response_node, response_pid} ->
        Task.Supervisor.start_child(:session_identity_task_supervisor, fn->
          session = %SessionIdentityModel{ connection_id: connection_id, connection_response_node: Atom.to_string(connection_response_node)  }
          created_session = GenServer.call(:session_identity_workflow_worker, {:create_session, session})
              send response_pid, {:create_session_response, :ok, created_session}
          end)
        workflow_service_loop()
      {:create_session, connection_id, connection_response_node}->
        Task.Supervisor.start_child(:session_identity_task_supervisor, fn->
          session = %SessionIdentityModel{ connection_id: connection_id, connection_response_node: Atom.to_string(connection_response_node)  }
          created_session = GenServer.call(:session_identity_workflow_worker, {:create_session, session})
          end)
        workflow_service_loop()
      {:remove_session_by_connection_id, connectionId, response_pid} ->
        Task.Supervisor.start_child(:session_identity_task_supervisor, fn->
        GenServer.call(:session_identity_workflow_worker, {:remove_session_by_connection_id, connectionId})
        send response_pid, {:remove_session_response, :ok}
      end)
      workflow_service_loop()
      {:remove_session_by_connection_id,  connectionId} ->
        Task.Supervisor.start_child(:session_identity_task_supervisor, fn->
          {:ok} = GenServer.call(:session_identity_workflow_worker, {:remove_session_by_connection_id, connectionId})
        end)
        workflow_service_loop()
    end

  end
  def handle_call({:initialize_database}, _from, state) do
    q = from m in SessionIdentityModel
    IdentityRepo.delete_all(q)
    {:reply, {:ok}, state}
  end
  def handle_call({:create_session, session}, _from, state) do
    created_session = IdentityRepo.insert!(session)
    {:reply, {:ok, created_session}, state}
  end
  def handle_call({:remove_session_by_connection_id, connection_id}, _from, state) do
    session = IdentityRepo.get_by!(SessionIdentityModel, connection_id: connection_id)
    GenServer.cast(:account_identity_workflow_worker, {:remove_session_id, session.id})
    q = from m in SessionIdentityModel, where: m.connection_id == ^connection_id

    IdentityRepo.delete_all(q)
    {:reply, {:ok}, state}
  end
  def handle_cast({:set_account, session, account_id}, state) do
    update_session = Ecto.Changeset.change session, session_account: account_id
    IdentityRepo.update update_session
    {:noreply, state}
  end
  def handle_call({:authenticate, principal, password}, _from, state) do
    case Aeacus.authenticate %{identity: principal, password: password} do
      {:ok, user}->{:reply, {:authenticate_success, user}, state}
      {:error, message}->{:reply, {:authenticate_failure, message}, state}
    end
  end
  def handle_call({:get_session_by_connection_id, connection_id}, _from, state) do
    #q = from m in SessionIdentityModel, where: m.connection_id == ^connection_id
    session = IdentityRepo.get_by!(SessionIdentityModel, connection_id: connection_id)
    {:reply, {:ok, session}, state}
  end
end
