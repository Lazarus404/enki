defmodule Enki.Message do
  @moduledoc """
  Message structure returned when dequeuing.
  """
  alias Memento.Table.Definition

  @doc false
  defmacro __using__(opts) do
    opts =
      opts
      |> Keyword.put(:type, :ordered_set)
      |> Keyword.put(:autoincrement, false)

    Definition.validate_options!(opts)

    quote do
      opts = unquote(opts)

      @table_attrs [:enki_id | Keyword.get(opts, :attributes)] |> Enum.uniq()
      @table_type Keyword.get(opts, :type)
      @table_opts Definition.build_options(opts)

      @query_map Definition.build_map(@table_attrs)
      @query_base Definition.build_base(__MODULE__, @table_attrs)

      @info %{
        meta: Memento.Table,
        type: @table_type,
        attributes: @table_attrs,
        options: @table_opts,
        query_base: @query_base,
        query_map: @query_map,
        primary_key: hd(@table_attrs),
        size: length(@table_attrs)
      }

      defstruct Definition.struct_fields(@table_attrs)
      def __info__, do: @info
    end
  end

  @type t :: %{
          enki_id: String.t()
        }
end
