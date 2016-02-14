defmodule SessionIdentityModel do
  @moduledoc """
  """
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "session_identity_model" do
    field :connection_id, :integer
    field :connection_response_node, :string
    field :session_create_time, Ecto.DateTime, default: Ecto.DateTime.utc()
    field :session_account_id, :binary_id
  end
end
