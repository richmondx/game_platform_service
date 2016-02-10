defmodule AccountIdentityModel do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "account_identity_model" do
    field :account_name, :string
    field :account_principal, :string
    field :account_password, :string
    field :account_enabled, :boolean, default: true
    field :account_create_date, Ecto.DateTime, default: Ecto.DateTime.utc()
    field :login_session, :binary_id
  end
end
