defmodule IslandsEngine.GameSupervisor do

  use DynamicSupervisor
  alias IslandsEngine.Game

  ## API ##
  # The behavior DynamicSupervisor has a start_child/2 function that is included by default
  # Dynamically adds a child specification to supervisor and starts that child.
  # https://hexdocs.pm/elixir/1.13/DynamicSupervisor.html#start_child/2
  def start_game(name), do: DynamicSupervisor.start_child(__MODULE__, {Game, name})

  def stop_game(name) do
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  # Application arg value passes into init_arg
  # links supervisor process to calling process (IslandsEngine.Application)
  def start_link(arg) do
    # as part of the start_link function, passes init_arg into the init callback
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)

  end

  def pid_from_name(name) do
    name
    |> Game.register_process
    |> GenServer.whereis()
  end

  ## Callback ##
  @impl true
  # actually starts the supervisor process
  # The default implementation initializes the supervisor with
  # an empty list of child specifications,
  # which means it won't supervise any processes by default.
  def init(_args) do

    DynamicSupervisor.init([Game])
  end

end
