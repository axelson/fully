defmodule FullyTest do
  use ExUnit.Case
  doctest Fully

  test "greets the world" do
    assert Fully.hello() == :world
  end
end
