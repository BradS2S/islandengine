defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Guesses, Coordinate, Island, Board, Rules}

  # module attribute
  @players [:player1, :player2]

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_islands, player, key, row, col})
  end

  def player_board(state_data, player), do: Map.get(state_data, player).board

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  # client function needs pid only
  def demo_call(game), do: GenServer.call(game, :demo_call)
  def demo_cast(game, new_value), do: GenServer.cast(game, {:demo_cast, new_value})

  def handle_info(:first, state) do
    IO.puts("stuff")
    {:noreply, state}
  end

  # calls are synchronous
  def handle_call(:demo_call, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:position_islands, player, key, row, col}, _from, state_data) do
    board = player_board(state_data, player)

    with {:ok, rules} <- Rules.check(state_data.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island) do
      state_data
      |> IO.inspect()
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state_data}
      {:error, :overlapping_island} -> {:reply, {:error, :overlapping_island}, state_data}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state_data}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state_data}
    end
  end

  def handle_call({:add_player, name}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player) do
      state_data
      |> add_player_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state_data}
    end
  end

  defp add_player_name(%{player2: %{name: player2_name}} = state_data, name)
       when player2_name == nil do
    put_in(state_data.player2.name, name)
  end

  defp update_rules(state_data, rules), do: %{state_data | rules: rules}
  defp reply_success(state_data, :ok), do: {:reply, :ok, state_data}
  # casts are asynchronous
  def handle_cast({:demo_cast, new_value}, state) do
    {:noreply, Map.put(state, :test, new_value)}
  end

  defp update_board(state_data, player, board) do
    Map.update!(state_data, player, fn player -> %{player | board: board} end)
  end
end
