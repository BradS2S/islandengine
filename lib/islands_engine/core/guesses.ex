defmodule IslandsEngine.Guesses do
  alias IslandsEngine.{Guesses, Coordinate}

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  def new() do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end

  # Transforming data

  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coordinate) do
    update_in(guesses.hits, &MapSet.put(&1, coordinate))
  end
  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coordinate) do
    update_in(guesses.misses, fn x -> MapSet.put(x, coordinate) end)
  end
end
