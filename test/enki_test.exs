defmodule EnkiTest do
  use ExUnit.Case, async: false
  alias Enki.Message
  doctest Enki

  defmodule Quibble do
    defstruct a: nil, b: nil
  end

  @ttf 500

  setup do
    Enki.delete_all()
    :ok
  end

  test "add a message to the queue" do
    msg = %Quibble{a: 1, b: 2}
    assert %Message{__meta__: Memento.Table, id: _, payload: ^msg} = Enki.enq(msg)
  end

  test "dequeue a message when empty returns nil" do
    assert nil == Enki.deq()
  end

  test "dequeuing a message deletes it from the queue" do
    msg = %Quibble{a: 3, b: 4}
    %Message{} = Enki.enq(msg)
    assert %Message{__meta__: Memento.Table, id: id, payload: ^msg} = Enki.deq(@ttf)
    assert nil == Enki.get(id)
    assert Enki.child_exists?(id)
    Enki.monitor(id) |> wait_for_death()
  end

  test "dequeued message is requeued if not ack'd" do
    msg = %Quibble{a: 5, b: 6}
    %Message{} = Enki.enq(msg)
    assert %Message{__meta__: Memento.Table, id: id, payload: ^msg} = Enki.deq(@ttf)
    assert Enki.child_exists?(id)
    Enki.monitor(id) |> wait_for_death()
    refute Enki.child_exists?(id)
    assert %Message{__meta__: Memento.Table, id: id, payload: ^msg} = Enki.get(id)
  end

  test "dequeued message remains absent if ack'd" do
    msg = %Quibble{a: 5, b: 6}
    %Message{} = Enki.enq(msg)
    assert %Message{__meta__: Memento.Table, id: id, payload: ^msg} = Enki.deq(@ttf)
    assert Enki.child_exists?(id)
    assert :ok == Enki.ack(id)
    Enki.monitor(id) |> wait_for_death()
    refute Enki.child_exists?(id)
    assert nil == Enki.get(id)
  end

  defp wait_for_death({ref, pid}) do
    receive do
      {:DOWN, ^ref, :process, ^pid, _} ->
        :timer.sleep(500)
        :ok
    end
  end

  defp wait_for_death(_),
    do: :ok
end
