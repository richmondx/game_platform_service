# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "GameIdentityService",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: APPLICATION_SECRET_KEY_HERE,
  serializer: MyApp.GuardianSerializer

  config :aeacus, Aeacus,
    repo: IdentityRepo,
    model: AccountIdentityModel,
    # Optional, The following are the default options
    crypto: Comeonin.Pbkdf2,
    identity_field: :account_principal,
    password_field: :account_password,
    error_message: "Invalid identity or password."

  config :identity_repo, IdentityRepo,
    database: "identity",
    username: "account_service",
    password: "account_pwd",
    hostname: "localhost"
  config :account_identity_workflow,
    initialize_database: true
# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :game_identity_service, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:game_identity_service, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
