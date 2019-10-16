defmodule Enki.MixProject do
  use Mix.Project

  def project(),
    do: [
      app: :enki,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        extras: ["README.md", "LICENSE.md"],
        main: "readme"
      ]
    ]

  def application(),
    do: [
      extra_applications: [:logger, :memento],
      mod: {Enki, []}
    ]

  defp deps(),
    do: [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:uuid, "~> 1.1"},
      {:memento, "~> 0.3.1"}
    ]

  defp description(),
    do: """
    A simple queue with Mnesia persistence and TTF
    """

  defp package(),
    do: [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Jahred Love"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/Lazarus404/enki"}
    ]
end
