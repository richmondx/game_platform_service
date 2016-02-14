defmodule SessionIdentityTokenSerializer do
  @moduledoc """
  """
    @behaviour Guardian.Serializer

    alias IdentityRepo
    alias AccountIdentityModel

    def for_token(user = %AccountIdentityModel{}), do: { :ok, "User:#{user.id}" }
    def for_token(_), do: { :error, "Unknown resource type" }

    def from_token("User:" <> id), do: { :ok, IdentityRepo.get(AccountIdentityModel, id) }
    def from_token(_), do: { :error, "Unknown resource type" }
end
