defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Guesses, Coordinate, Island, Board, Rules}


  ## Players, opponents
  @players [:player1, :player2]
  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  ## Client API

  # Start a new game
  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  # Island(s)
  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  def update_guesses(state_data, player_key, hit_or_miss, coordinate) do
    update_in(state_data[player_key].guesses, fn guesses -> Guesses.add(guesses, hit_or_miss, coordinate) end)
  end

  # Player
  def player_board(state_data, player), do: Map.get(state_data, player).board

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  defp add_player_name(%{player2: %{name: player2_name}} = state_data, name) when player2_name == nil do
    put_in(state_data.player2.name, name)
  end

  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end
  # Board
  defp update_board(state_data, player, board) do
    Map.update!(state_data, player, fn player -> %{player | board: board} end)
  end


  #Rules
  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  defp reply_success(state_data, reply), do: {:reply, reply, state_data}

  # Examples of API
  def demo_call(game), do: GenServer.call(game, :demo_call)
  def demo_cast(game, new_value), do: GenServer.cast(game, {:demo_cast, new_value})

  ## Defining GenServer Callbacks

  @impl true
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  @impl true
  def handle_info(:first, state) do
    #IO.puts("stuff")
    {:noreply, state}
  end

  # calls are synchronous
  @impl true
  def handle_call(:demo_call, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:position_island, player, key, row, col}, _from, state_data) do
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

  @impl true
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

  @impl true
  @spec handle_call({atom, atom}, GenServer.from(), struct) :: map, {atom, %Board{}} | {:reply, :error, map} | {:reply, {:error, atom}, map}
  def handle_call({:set_islands, player}, _from, state_data) do
    board = player_board(state_data, player)
    with {:ok, rules} <- Rules.check(state_data.rules, {:set_islands, player}),
         true         <- Board.all_islands_positioned?(board)
         do
           state_data
           |> update_rules(rules)
           |>reply_success({:ok, board})
         else
          :error -> {:reply, :error, state_data}
          false -> {:reply, {:error, :not_all_islands_positioned}, state_data}
         end
  end

  @impl true
  def handle_call({:guess_coordinate, player_key, row, col}, _from, state_data) do
    opponent_key = opponent(player_key)
    opponent_board = player_board(state_data, opponent_key)
    with  {:ok, rules} <- Rules.check(state_data.rules, {:guess_coordinate, player_key}),
          {:ok, coordinate} <- Coordinate.new(row, col),
          {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
          {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
    do
          state_data
          |> update_board(opponent_key, opponent_board)
          |> update_guesses(player_key, hit_or_miss, coordinate)
          |> update_rules(rules)
          |> reply_success({hit_or_miss, forested_island, win_status})
    else

      :error -> {:reply, :error, state_data}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state_data}

    end
  end


  # casts are asynchronous

  @impl true
  @spec handle_cast({atom, any}, struct) :: {atom, struct}
  def handle_cast({:demo_cast, new_value}, state) do
    {:noreply, Map.put(state, :test, new_value)}
  end


end
