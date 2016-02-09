defmodule AccountIdentityService do
  use Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: name())
  end
  def name() do
    String.to_atom("account_identity_supervisor")
  end
  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: task_supervisor_name()]]),
      worker(AccountIdentityWorkflow, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
  def task_supervisor_name() do
    String.to_atom("account_identity_task_supervisor")
  end
end
