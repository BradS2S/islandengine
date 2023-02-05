defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
            player1: :islands_not_set,
            player2: :islands_not_set

  @spec new :: %IslandsEngine.Rules{
          player1: :islands_not_set,
          player2: :islands_not_set,
          state: :initialized
        }
  def new(), do: %Rules{}

  ## Rules.state check

  # :initialized
  def check(%Rules{state: :initialized} = rules, :add_player),
    do: {:ok, %Rules{rules | state: :players_set}}

  # :players_set
  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set, player1: :islands_set},
            {:position_islands, :player1}),
    do: :error

  def check(%Rules{state: :players_set, player1: :islands_not_set} = rules,
            {:position_islands, :player1}),
      do: {:ok, rules}

  def check(%Rules{state: :players_set, player2: :islands_set},
            {:position_islands, :player2}),
    do: :error

  def check(%Rules{state: :players_set, player2: :islands_not_set} = rules,
            {:position_islands, :player2}),
      do: {:ok, rules}

  # :player1_turn
  def check(%Rules{state: :player1_turn}  = rules, {:win_check, :no_win}), do: {:ok, rules}
  def check(%Rules{state: :player1_turn}  = rules, {:win_check, :win}) do
    {:ok, %Rules{rules | state: :game_over}}
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}),
    do: {:ok, %Rules{rules | state: :player2_turn}}

  # :player2_turn
  def check(%Rules{state: :player2_turn} = rules, {:win_check, :no_win}), do: {:ok, rules}
  def check(%Rules{state: :player2_turn} = rules, {:win_check, :win}) do
    {:ok, %Rules{rules | state: :game_over}}
  end

  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}),
    do: {:ok, %Rules{rules | state: :player1_turn}}

  # any other state returns an error
    def check(_rules_state, _action), do: :error

  defp both_players_islands_set?(rules),
    do: rules.player1 == :islands_set && rules.player2 == :islands_set
end
