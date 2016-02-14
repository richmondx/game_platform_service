defmodule SessionIdentityService do
  @moduledoc """
  """
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("session_identity_supervisor")
  end
  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: task_supervisor_name()]]),
      worker(SessionIdentityWorkflow, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
  def task_supervisor_name() do
    String.to_atom("session_identity_task_supervisor")
  end
end
