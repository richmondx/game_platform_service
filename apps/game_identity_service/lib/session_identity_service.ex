defmodule SessionIdentityService do
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("session_identity_service_supervisor")
  end
  def init(:ok) do
    children = [

    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
