defmodule Fully.Server do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = %{}
    Fully.connect_uart(name: Fully)
    {:ok, state}
  end
end
