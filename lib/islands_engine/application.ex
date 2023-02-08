defmodule IslandsEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  # _args are the arguments passed to the application in the :mod specification key
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: IslandsEngine.Worker.start_link(arg)
      {IslandsEngine.GameSupervisor, Game},
      {Registry, keys: :unique, name: Registry.Game}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
