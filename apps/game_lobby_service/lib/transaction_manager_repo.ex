defmodule TransactionManagerRepo do
  use GenServer
  require Logger
  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__,  %{}, [])
    Process.register(pid, String.to_atom("routing_service_transaction_repo"))
    {:ok, pid}
  end
  def init(state) do
    ets = :ets.new(:pending_transactions, [:set, :protected])
    {:ok, %{repo: ets}}
  end
  def build_key(t) when is_integer(t) do
    "key_"<>Integer.to_string(t)
  end
  def build_key(t) do
    "key_"<>Integer.to_string(t.transaction_id)
  end
  def insert(transaction) do
    GenServer.cast(self(), {:insert, transaction})
  end
  def get(transaction_id) do
    GenServer.call(self(), {:get, transaction_id})
  end
  def handle_call({:get, id}, _from, state) do
    k = build_key(id)
    lookup = :ets.lookup(Map.get(state, :repo), k)
    {:reply, lookup, state}
  end
  def handle_cast({:insert, item}, state) do
    k = build_key(item)
    :ets.insert( Map.get(state, :repo),  {k, Map.from_struct(item)}  )
    {:noreply, state}
  end
end
