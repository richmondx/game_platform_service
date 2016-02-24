defmodule LobbyService do
  @moduledoc """
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      # Define workers and child supervisors to be supervised
      supervisor(RoutingServiceSupervisor, []),
      worker(TcpConnectionSupervisor, []),
      worker(EchoService, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LobbyService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
