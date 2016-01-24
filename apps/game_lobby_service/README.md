# LobbyService

* A LobbyService for game clients written in Elixir

https://excavationofimagination.wordpress.com/


## Version History
* 0.0.4 -> moved to umbrella project
* 0.0.3 -> tcp_ip optimizations - throttled queues with auto flush + moved settings to config.exs
* 0.0.2 -> refactor tcp_ip, add external EchoService
* 0.0.1 -> Initial Add, starting tcp_ip listener/handler

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add game_lobby_service to your list of dependencies in `mix.exs`:

        def deps do
          [{:game_lobby_service, "~> 0.0.4"}]
        end

  2. Ensure game_lobby_service is started before your application:

        def application do
          [applications: [:game_lobby_service]]
        end
