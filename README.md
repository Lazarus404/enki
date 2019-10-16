# Enki

Enki is a simple persistable message queue that utilises Mnesia.

## Why Enki?

Enki phonetically sounds like a shortened term for Enqueue. It's also the name of the Sumerian God of Creation (cue rock music!).

## Installation

Add the following to your `deps` in your `mix.exs` file.

```elixir
def deps do
  [
    {:enki, "~> 0.1"}
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

## Documentation

Documentation can be found at [https://hexdocs.pm/enki](https://hexdocs.pm/enki).

