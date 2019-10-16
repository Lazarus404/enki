defmodule Enki do
  @moduledoc """
  Enki is a simple queue that provides Mnesia persistence across nodes and
  `ttf` (time-to-flight) capability.

  Time-to-flight means that, when dequeuing a message, if the dequeue is not
  ack'd within a given period of time, the message is automatically added
  back to the queue. This ensures that no messages are lost.

  ## Examples

      Enki.enq(%{a: 1, b: 2})
      
      %{id: id, payload: %{a: 1, b: 2}} = Enki.deq()

      :ok = Enki.ack(id)
  """

  @moduledoc since: "0.1.0"

  alias Enki.Message

  defmodule Counter do
    @moduledoc false
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> 0 end, name: __MODULE__)
    end

    def next_value() do
      Agent.get(__MODULE__, &(&1 + 1))
    end
  end

  @sup Enki.SupervisedClients

  @doc """
  Enki application start method.

  Gets called automatically when included in your `mix` 
  `applications` list.
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    if file_persist() do
      Memento.stop()
      Memento.Schema.create(nodes())
      Memento.start()
      maybe_create_table(disc_copies: nodes())
    else
      maybe_create_table()
    end

    children = [
      worker(Counter, [[]]),
      {DynamicSupervisor, strategy: :one_for_one, name: @sup}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Enki.Supervisor,
      max_restarts: 10_000
    )
  end

  @doc """
  Adds a message to the queue.

  Returns a Message instance containing the `id` of the message
  on the queue and the message itself as a `payload`.
  """
  @spec enq(any()) :: Message.t()
  def enq(message) do
    Memento.transaction!(fn ->
      id = Counter.next_value()
      Memento.Query.write(%Message{id: "#{id}_#{UUID.uuid4(:hex)}", payload: message})
    end)
  end

  @doc """
  Dequeues a message from the queue.

  Returns the message in a `Message` struct as its
  `payload` parameter. The message is typically the oldest in
  the queue.

  ## Parameters

  | name | description |
  | ---- | ----------- |
  | `ttf` | The time-to-flight for the message. If provided, verrides the message in the config (optional). |
  """
  def deq(ttf \\ nil) do
    with %Enki.Message{id: id} = message <- deq_(),
         {:ok, _pid} <-
           DynamicSupervisor.start_child(
             @sup,
             Supervisor.child_spec(
               {Enki.InFlight,
                message: message, ttf: ttf || time_to_flight(), id: child_name(id)},
               id: child_name(id),
               restart: :transient
             )
           ) do
      message
    end
  end

  @doc """
  Acknowledges a dequeued message.

  If the message is in-flight, it will not be re-added to the queue
  after the alotted `ttf`.

  ## Parameters

  | name | description |
  | ---- | ----------- |
  | `id` | The `id` of the message to acknowledge (required). |
  """
  def ack(id) do
    child_exit(id)
  end

  @doc """
  Retrieves a message by `id` without dequeuing.

  Recalling a message directly does NOT put it in flight.

  ## Parameters

  | name | description |
  | ---- | ----------- |
  | `id` | The `id` of the message to retrieve (required). |
  """
  def get(id) do
    Memento.transaction!(fn ->
      Memento.Query.read(Message, id)
    end)
  end

  @doc """
  Deletes a message by `id`.

  Directly deletes a message in the queue.

  ## Parameters

  | name | description |
  | ---- | ----------- |
  | `id` | The `id` of the message to delete (required). |
  """
  def delete(id) do
    Memento.transaction!(fn ->
      case get(id) do
        %Message{id: id} ->
          child_exit(id)
          Memento.Query.delete(Message, id)

        _ ->
          :ok
      end
    end)
  end

  @doc """
  Delete all messages in the queue.

  Any in-flight messages are cancelled, so messages are not 
  added back to the queue.
  """
  def delete_all() do
    Memento.transaction!(fn ->
      Memento.Query.all(Message)
      |> Enum.each(fn rec ->
        child_exit(rec.id)
        Memento.Query.delete_record(rec)
      end)
    end)
  end

  @doc false
  def child_exists?(id),
    do:
      child_name(id)
      |> Process.whereis()
      |> is_alive?()

  @doc false
  def monitor(id),
    do:
      child_name(id)
      |> Process.whereis()
      |> monitor_()

  defp maybe_create_table(opts \\ []) do
    try do
      Memento.Table.info(Message)
    catch
      :exit, _ -> Memento.Table.create!(Message, opts)
    end
  end

  defp deq_() do
    Memento.transaction!(fn ->
      with [%Message{} = msg] <- Memento.Query.select(Message, [], limit: 1),
           _ <- Memento.Query.delete_record(msg) do
        msg
      else
        [] ->
          nil
      end
    end)
  end

  defp child_exit(id) do
    if child_name(id) |> Process.whereis() |> is_alive?() do
      GenServer.stop(child_name(id))
    end

    :ok
  end

  defp child_name(id),
    do: "enki_#{inspect(id)}" |> String.to_atom()

  defp is_alive?(pid) when is_pid(pid),
    do: Process.alive?(pid)

  defp is_alive?(_),
    do: false

  defp monitor_(pid) when is_pid(pid),
    do: {Process.monitor(pid), pid}

  defp monitor_(_),
    do: nil

  defp nodes(),
    do: [node() | Node.list()]

  defp time_to_flight(),
    do: Application.get_env(:enki, :ttf, 5000)

  defp file_persist(),
    do: Application.get_env(:enki, :file_persist, false)
end
