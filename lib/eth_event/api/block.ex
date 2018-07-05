defmodule EthEvent.Api.Block do
  @moduledoc """
  Defines the `Block` event.

  In order to request a `Block`, you have to specify the desired `block_number`
  by setting it in the event struct itself (if no `block_number` is set, then
  defaults to `"latest"`) e.g:
  ```
  > alias EthEvent.Api.Block
  > {:ok, %Block{} = block} = Block.query(%Block{block_number: 0})
  > block
  %Block{
    block_number: 0,
    block_hash: "0xb7381ade07e036e0f9195446f54b6c5e6228a10d3ff750dedb8a5c2372db2b3c",
    type: "mined",
    ...
    timestamp: #DateTime<...>
  }
  ```
  """
  use EthEvent.Schema, method: "eth_getBlockByNumber"

  alias EthEvent.Decode

  event "Block" do
    uint :timestamp
  end

  @doc """
  Builds the query to get the basic information of a block. It receives the
  `Block` `event` and some `options` as `Keyword` list.
  """
  @spec build_query(EthEvent.Schema.t(), Keyword.t()) ::
    {:ok, term()} | {:error, term()}
  def build_query(event, options)

  def build_query(%__MODULE__{block_number: nil} = event, options) do
    build_query(%{event | block_number: "latest"}, options)
  end
  def build_query(%__MODULE__{block_number: block_number}, _options) do
    {:ok, [block_number, false]}
  end

  @doc """
  Decodes the `result` from the `Block` `event` query and places it in the
  `Block` struct.
  """
  @spec build_result(EthEvent.Schema.t(), term()) ::
    {:ok, EthEvent.Schema.t()} | {:error, term()}
  def build_result(event, result)

  def build_result(%__MODULE__{} = _event, result) do
    case do_build_result(result) do
      nil ->
        {:error, "Invalid block result"}
      result ->
        {:ok, result}
    end
  end

  @doc false
  def do_build_result(
    %{"number" => block_number,
      "hash" => block_hash,
      "timestamp" => timestamp,
      "transactions" => transactions
    }
  ) when not is_nil(block_number) and not is_nil(block_hash) do
    %__MODULE__{}
    |> add(:block_hash, block_hash)
    |> add(:block_number, block_number)
    |> add(:type, "mined")
    |> add(:timestamp, timestamp)
    |> add(:extra, transactions)
  end
  def do_build_result(
    %{"transactions" => transactions, "timestamp" => timestamp}
  ) do
    %__MODULE__{
      block_hash: "pending",
      block_number: "pending",
      type: "pending",
    }
    |> add(:timestamp, timestamp)
    |> add(:extra, transactions)
  end

  @doc false
  def add(%__MODULE__{} = event, :block_number, block_number) do
    with {:ok, block_number} <- Decode.cast({:uint, 256}, block_number) do
      %{event | block_number: block_number}
    end
  end
  def add(%__MODULE__{} = event, :block_hash, block_hash) do
    %{event | block_hash: block_hash}
  end
  def add(%__MODULE__{} = event, :type, type) do
    %{event | type: type}
  end
  def add(%__MODULE__{} = event, :timestamp, timestamp) do
    with {:ok, timestamp} <- Decode.cast({:uint, 256}, timestamp),
         {:ok, timestamp} <- DateTime.from_unix(timestamp) do
      %{event | timestamp: timestamp}
    end
  end
  def add(%__MODULE__{} = event, :extra, extra) do
    %{event | extra: extra}
  end
  def add(_, _, _) do
    nil
  end
end
