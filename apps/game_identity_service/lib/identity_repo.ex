defmodule IdentityRepo do
  use Ecto.Repo,
    otp_app: :identity_repo,
    adapter: Mongo.Ecto
end
