defmodule EthEvent.Api.Balance do
  @moduledoc """
  Defines the `Balance` event.

  In order to request a `Balance`, you have to specify the desired `address`
  and `block_number` (defaults to `"latest"`) by setting it in the event struct
  itself e.g:

  ```
  > alias EthEvent.Api.Balance
  > {:ok, %Balance{} = balance} = Balance.query(%Balance{address: "0x93e..."})
  > balance
  %Balance{
    address: "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51",
    block_hash: "0xb7381ade07e036e0f9195446f54b6c5e6228a10d3ff750dedb8a5c2372db2b3c",
    block_number: 0,
    type: "mined",
    balance: 100000000000000000000, # In Wei
    ...
  }
  ```

  This event can be composed with other events as long as `address` and
  (optionally `block_number`) are present in the other event e.g:

  ```
  > alias EthEvent.Api.{Block, Balance}
  > {:ok, %Block{} = block} = Block.query(%Block{}) # Latest block.
  > block
  %Block{
    block_number: 0,
    block_hash: "0xb7381ade07e036e0f9195446f54b6c5e6228a10d3ff750dedb8a5c2372db2b3c",
    type: "mined",
    ...
  }
  > {:ok, %Balance{} = balance} = Balance.query(%{block | address: "0x93e..."})
  > balance
  %Balance{
    address: "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51",
    block_hash: "0xb7381ade07e036e0f9195446f54b6c5e6228a10d3ff750dedb8a5c2372db2b3c",
    block_number: 0,
    type: "mined",
    balance: 100000000000000000000, # In Wei
    ...
  }
  ```
  """
  use EthEvent.Schema, method: "eth_getBalance"

  alias EthEvent.Decode

  event "Balance" do
    uint256 :balance
  end

  @doc """
  Builds the query to get the balance of an account. It receives the an
  `event`. some initial `parameters` and some `options` as `Keyword` list.
  """
  @spec build_query(EthEvent.Schema.t(), Keyword.t()) ::
    {:ok, term()} | {:error, term()}
  def build_query(event, options)

  def build_query(%__MODULE__{address: nil}, _options) do
    {:error, "Address not specified"}
  end
  def build_query(%__MODULE__{block_number: nil} = event, options) do
    build_query(%{event | block_number: "latest"}, options)
  end
  def build_query(%__MODULE__{address: address, block_number: number}, _) do
    {:ok, [address, number]}
  end

  @doc """
  Decodes the `result` from the `Balance` `event` query and places it in the
  `Balance` struct.
  """
  @spec build_result(EthEvent.Schema.t(), term()) ::
    {:ok, EthEvent.Schema.t()} | {:error, term()}
  def build_result(event, result)

  def build_result(%__MODULE__{} = event, result) do
    with {:ok, balance} <- Decode.cast({:uint, 256}, result) do
      {:ok, %{event | balance: balance}}
    end
  end
end
