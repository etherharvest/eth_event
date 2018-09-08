defmodule EthEvent.MixProject do
  use Mix.Project

  @version "0.1.1"
  @root "https://github.com/etherharvest/eth_event"

  def project do
    [
      app: :eth_event,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  #############
  # Application

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end
  defp elixirc_paths(_) do
    ["lib"]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:exth_crypto, "~> 0.1"},
      {:tesla, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:skogsra, "~> 0.2"},
      {:ex_doc, "~> 0.18.4", only: :dev},
      {:credo, "~> 0.10", only: :dev}
     ]
  end

  #########
  # Package

  defp package do
    [
      description: "Ethereum event requester",
      files: ["lib", "mix.exs", "README.md", "test/support"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
        "Github" => @root
      }
    ]
  end

  ###############
  # Documentation

  defp docs do
    [
      source_url: @root,
      source_ref: "v#{@version}",
      main: EthEvent,
      formatters: ["html"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "EthEvent": [
        EthEvent,
        EthEvent.Settings
      ],
      "Declaring events": [
        EthEvent.Schema
      ],
      "Built-in events": [
        EthEvent.Api.Block,
        EthEvent.Api.Balance
      ],
      "Decoder": [
        EthEvent.Decode
      ],
      "Encoder": [
        EthEvent.Encode
      ],
      "Transport": [
        EthEvent.Transport
      ]
    ]
  end
end
