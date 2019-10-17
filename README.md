# Enki

Enki is a simple persistable message queue that utilises Mnesia.

## Why Enki?

Enki phonetically sounds like a shortened term for Enqueue. It's also the name of the Sumerian God of Creation (cue rock music!).

## Installation

Add the following to your `deps` in your `mix.exs` file.

```elixir
def deps do
  [
    {:enki, "~> 0.2"}
  ]
end
```
Then, add `:enki` to your list of applications.

```elixir
def application do
  [
    extra_applications: [:enki, ...],
    mod: {YourApp, []}
  ]
end
```

## Configuration

There are several options to configure Enki.

```elixir
config :enki,
  ttf: 5000,           # number of milliseconds to keep message in-flight
  file_persist: false  # determines whether to use Mnesia's file persistences
```

## Usage

Enki is a simple queue. It doesn't enforce FIFO (first in first out) and so isn't a strict queue, but it is a great
little tool for maintaining data you will want to consumer over time, such as where queues are typically implmeneted.

Enki provides in-flight management. Thus, when dequeuing a value, if it is not `ack`'d within the duration of the 
`ttf` (time-to-flight) setting, the value will be replaced into the queue.

To use, create a module to use as a message:

```elixir
defmodule MyApp.MyModel do
  use Enki.Message,
    attributes: [:attr1, :attr2]
end
```

This replaces any equivelent struct, so do not create is as:

```elixir
defmodule MyApp.MyModel do
  defstruct attr1, attr2
end
```

The `use` option ensures the model includes meta needed by Enki.

Next, you need to initialise the queue. You can initialise multiple queues at once, if needed:

```elixir
Enki.init([MyApp.MyModel])
```

Once initialised, you can then enqueue and dequeue as needed:

```elixir
Enki.enq(%MyModel{attr1: 1, attr2: 2})
%MyModel{enki_id: id, attr1: 1, attr2: 2} = Enki.deq(MyModel)
# ... process data
Enki.ack(id)
```
The `ack` must be called within the given `ttf` period (in milliseconds). Otherwise, the message will be re-queued.

## Documentation

Documentation can be found at [https://hexdocs.pm/enki](https://hexdocs.pm/enki).

