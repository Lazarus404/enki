defmodule EnkiTest do
  use ExUnit.Case, async: false
  doctest Enki

  defmodule Quibble do
    use Enki.Message,
      attributes: [:a, :b]
  end

  defmodule Tribble do
    use Enki.Message,
      attributes: [:c, :d, :e]
  end

  @ttf 500

  setup_all do
    Enki.init([Quibble, Tribble])
    :ok
  end

  setup do
    Enki.delete_all(Quibble)
    Enki.delete_all(Tribble)
    :ok
  end

  test "add a message to the queue" do
    msg = %Quibble{a: 1, b: 2}
    assert %Quibble{__meta__: Memento.Table, enki_id: _, a: 1, b: 2} = Enki.enq(msg)
  end

  test "dequeue a message when empty returns nil" do
    assert nil == Enki.deq(Quibble)
  end

  test "dequeuing a message deletes it from the queue" do
    msg = %Quibble{a: 3, b: 4}
    %Quibble{} = Enki.enq(msg)
    assert %Quibble{__meta__: Memento.Table, enki_id: id, a: 3, b: 4} = Enki.deq(Quibble, @ttf)
    assert nil == Enki.get(Quibble, id)
    assert Enki.child_exists?(id)
    Enki.monitor(id) |> wait_for_death()
  end

  test "dequeued message is requeued if not ack'd" do
    msg = %Quibble{a: 5, b: 6}
    %Quibble{} = Enki.enq(msg)
    assert %Quibble{__meta__: Memento.Table, enki_id: id, a: 5, b: 6} = Enki.deq(Quibble, @ttf)
    assert Enki.child_exists?(id)
    Enki.monitor(id) |> wait_for_death()
    refute Enki.child_exists?(id)
    assert %Quibble{__meta__: Memento.Table, enki_id: id, a: 5, b: 6} = Enki.get(Quibble, id)
  end

  test "dequeued message remains absent if ack'd" do
    msg = %Quibble{a: 7, b: 8}
    %Quibble{} = Enki.enq(msg)
    assert %Quibble{__meta__: Memento.Table, enki_id: id, a: 7, b: 8} = Enki.deq(Quibble, @ttf)
    assert Enki.child_exists?(id)
    assert :ok == Enki.ack(id)
    Enki.monitor(id) |> wait_for_death()
    refute Enki.child_exists?(id)
    assert nil == Enki.get(Quibble, id)
  end

  test "create and retrive messages from multiple queues" do
    msg = %Quibble{a: 9, b: 10}
    %Quibble{} = Enki.enq(msg)
    msg = %Tribble{c: 1, d: 2, e: 3}
    %Tribble{} = Enki.enq(msg)
    assert %Quibble{__meta__: Memento.Table, enki_id: _, a: 9, b: 10} = Enki.deq(Quibble, @ttf)

    assert %Tribble{__meta__: Memento.Table, enki_id: _, c: 1, d: 2, e: 3} =
             Enki.deq(Tribble, @ttf)
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
