defmodule EchoService do
  @moduledoc """
  """
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("echo_service_supervisor")
  end
  def init(:ok) do
    children = [
      worker(EchoServiceProcessor, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
