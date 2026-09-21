defmodule Circuit.MixProject do
  use Mix.Project

  def project do
    [
      app: :circuit,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuit_breaker,
       git: "https://github.com/klarna/circuit_breaker.git",
       tag: "1.0.1",
       manager: :rebar3},
      {:propcheck, "~> 1.1", only: [:test, :dev]}
    ]
  end
end
