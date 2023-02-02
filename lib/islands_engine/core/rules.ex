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




 def check(%Rules{} = rules, {:win_check, :no_win}), do: {:ok, rules}
 def check(%Rules{} = rules, {:win_check, :win}), do: {:ok, %Rules{rules | state: :game_over}}

 def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}), do: {:ok, %Rules{rules | state: :player2_turn}}
 def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}), do: {:ok, %Rules{rules | state: :player1_turn}}

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules
    |>Map.put(player, :islands_set)
    |>both_players_islands_set
  end

  def check(%Rules{state: :players_set, player1: :islands_set},     {:position_islands, :player1}),  do: :error
  def check(%Rules{state: :players_set, player1: :islands_not_set} = rules, {:position_islands, :player1}),  do: {:ok, rules}
  def check(%Rules{state: :players_set, player2: :islands_set},     {:position_islands, :player2}),  do: :error
  def check(%Rules{state: :players_set, player2: :islands_not_set} = rules, {:position_islands, :player2}),  do: {:ok, rules}
  def check(%Rules{state: :initialized} = rules, :add_player),  do: {:ok, %Rules{rules | state: :players_set}}
  def check(_rules_state, _action), do: :error

  defp both_players_islands_set(%Rules{player1: :islands_set, player2: :islands_set} = rules), do: {:ok, %Rules{rules | state: :player1_turn}}
  defp both_players_islands_set(rules), do: {:ok, rules}

end
