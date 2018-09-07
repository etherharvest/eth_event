defmodule EthEvent.Settings do
  @moduledoc """
  This module defines the available settings for `EthEvent`.
  """
  use Skogsra

  @doc """
  Node URL. Defaults to `"http://localhost:8545"`.

  ```
  config :eth_event,
    node_url: "https://mainnet.infura.io/v3"
  ```
  """
  app_env :eth_event_node_url, :eth_event, :node_url,
    default: "http://localhost:8545"

  @doc """
  Node URL. Defaults to `""`.

  ```
  config :eth_event,
    node_key: "some key"
  ```
  """
  app_env :eth_event_node_key, :eth_event, :node_key,
    default: ""
end
