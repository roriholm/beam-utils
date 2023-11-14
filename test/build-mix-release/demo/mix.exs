defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo,
      version: "0.1.0",
      elixir: "~> 1.15",
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
      # Elixir deps comes from Hex
      {:jason, "~> 1.4"},
      # # Erlang deps comes from Hex
      {:hackney, "~> 1.20"},
      # Deps comes from Git
      {:mint, github: "elixir-mint/mint", tag: "v1.5.1"}
    ]
  end
end
