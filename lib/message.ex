defmodule Enki.Message do
  @moduledoc """
  Message structure returned when dequeuing.
  """
  use Memento.Table,
    attributes: [:id, :payload],
    type: :ordered_set,
    autoincrement: true

  @type t :: %{
          id: String.t(),
          payload: any()
        }
end
