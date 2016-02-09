defmodule IdentityService do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(IdentityService.Worker, [arg1, arg2, arg3]),
      supervisor(AccountIdentityService, []),
      supervisor(SessionIdentityService, []),
      supervisor(IdentityRepo, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IdentityService.Supervisor]
    Supervisor.start_link(children, opts)
  end
  def name() do
    String.to_atom("identity_service_supervisor")
  end
end
