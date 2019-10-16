defmodule Enki.InFlight do
  @moduledoc false
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct ttf: 500, message: nil, id: nil
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    state = struct(State, opts)
    GenServer.start_link(__MODULE__, state, name: state.id)
  end

  @impl true
  def init(%State{} = state) do
    {:ok, state, state.ttf}
  end

  @impl true
  def handle_info(:timeout, state) do
    Memento.transaction!(fn ->
      Memento.Query.write(state.message)
    end)

    {:stop, :normal, state}
  end
end
