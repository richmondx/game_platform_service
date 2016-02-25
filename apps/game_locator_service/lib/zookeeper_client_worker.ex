defmodule ZookeeperClientWorker do
  @moduledoc"""
    Module to configure zookeeper, and make client available
  """
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, [])
    Process.register(pid, name())
    {:ok, pid}
  end
  def name() do
    String.to_atom("zookeeper_client_worker")
  end
  def init(state) do
    {:ok, pid} = Zookeeper.Client.start
    initialize_zookeeper_data(pid)
    {:ok, %{zookeeper: pid}}
  end


  defp delete_children(client, base_path ) do
    Logger.info "delete #{base_path}"
    case Zookeeper.Client.get_children(client, "#{base_path}") do
      {:ok, children}->
        for c<-children do
          :ok = Zookeeper.Client.delete(client, "#{base_path}/#{to_string(c)}")
        end
      other->Logger.info "other children: #{inspect other}"
    end
  end

  defp initialize_zookeeper_for_service(client, service) do
    Logger.info "initializing service #{service}"
    delete_children(client, "/services/#{service}")
    Logger.info "get #{"/services/#{service}"}"
    case Zookeeper.Client.get(client, "/services/#{service}") do
      {:ok, {data,_path}}->:ok = Zookeeper.Client.delete(client, "/services/#{service}")
      other->
        Logger.info "Other: #{inspect other}"
        :ok
    end

    case Zookeeper.Client.create(client, "/services/#{service}", "#{service} base_directory") do
      {:ok, _path}->nil
      {:error, :no_node}->create_base_zookeeper_service(client, service)
    end
  end
  defp create_base_zookeeper_service(client, service) do
    {:ok, _path} = Zookeeper.Client.create(client, "/services", "all_services base_directory")
    {:ok, _path} = Zookeeper.Client.create(client, "/services/#{service}", "#{service} base_directory")
  end
  defp initialize_zookeeper_data(client) do
    Logger.info "initializing zookeeper"
    services = Application.get_env(:zookeeper_service_configuration, :services)
    Logger.info "initialize services #{inspect services}"
    for srv<-services do
      Logger.info "initialize: #{srv}"
      case Application.get_env(:zookeeper_service_configuration, :force_initialize) do
        :true->
          Logger.info "initialize zookeeper #{srv}"
          initialize_zookeeper_for_service(client, srv)
        :false->Logger.info "false"
        other->Logger.info "other #{inspect other}"
      end
    end

  end

  def handle_call({:get_client}, _from, state) do
    {:reply, Map.get(state, :zookeeper), state}
  end


end
