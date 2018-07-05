defmodule EthEvent.Settings do
  @moduledoc """
  This module defines the available settings for `EthEvent`.
  """
  use Skogsra

  @doc """
  Node URL.

  ```
  config :eth_event,
    node_url: "https://example.com:8545"
  ```
  """
  app_env :node_url, :eth_event, :node_url,
    default: "http://localhost:8545"
end
