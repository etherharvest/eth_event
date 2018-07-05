defmodule EthEvent.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :eth_event,
      version: @version,
      elixir: "~> 1.6",
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
    [{:exth_crypto, "~> 0.1"},
     {:tesla, "~> 1.0"},
     {:jason, "~> 1.0"},
     {:skogsra, "~> 0.2"}
     ]
  end
end
