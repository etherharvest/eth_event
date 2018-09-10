defmodule EthEvent.TestNode do
  use Agent

  alias EthEvent.Encode
  alias EthEvent.Settings

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def get_block do
    name = __MODULE__
    block = Agent.get_and_update(name, fn block -> {block, block + 1} end)
    Encode.encode!(:quantity, block)
  end

  def server(%Tesla.Env{method: :post, body: body}) do
      body
      |> Jason.decode!()
      |> process_payload()
  end

  def server(%Tesla.Env{method: :post, body: body, url: url}) do
    if check_url(url) do
      body
      |> Jason.decode!()
      |> process_payload()
    else
      {:error, "Bad URL"}
    end
  end

  @doc false
  def check_url(url) do
    base = Settings.eth_event_node_url()
    case Settings.eth_event_node_key() do
      "" ->
        "#{base}/" == url
      key when is_binary(key) ->
        "#{base}/#{key}" == url
    end
  end

  @doc false
  def process_payload(
    %{"id" => id, "method" => "eth_getBalance"}
  ) do
    balance = Encode.encode!(:quantity, 100)
    result = %{"id" => id, "jsonrpc" => "2.0", "result" => balance}
    %Tesla.Env{status: 200, body: Jason.encode!(result)}
  end
  def process_payload(
    %{"id" => id, "method" => "eth_getBlockByNumber"}
  ) do
    result = %{
      "id" => id,
      "jsonrpc" => "2.0",
      "result" => %{
        "number" => get_block(),
        "hash" => "0x4d256e0bc11af8091043c13b07f0e59dd7c07172d4ba14d9f75454a3d182d71c",
        "extra" => [],
        "timestamp" => Encode.encode!(:quantity, :os.system_time(:seconds)),
        "transactions" => []
      }
    }
    %Tesla.Env{status: 200, body: Jason.encode!(result)}
  end
  def process_payload(
    %{
      "id" => id,
      "method" => "eth_getLogs",
      "params" => [params]
    }
  ) do
    address = Map.get(params, "address", "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e")
    topics = Map.get(params, "topics", [nil, nil, nil])

    result = %{
      "id" => id,
      "jsonrpc" => "2.0",
      "result" => [%{
        "address" => address,
        "blockHash" => "0x4d256e0bc11af8091043c13b07f0e59dd7c07172d4ba14d9f75454a3d182d71c",
        "blockNumber" => get_block(),
        "data" => "0x0000000000000000000000000000000000000000000000000000000000000064",
        "logIndex" => "0x0",
        "topics" => build_topics(topics)
      }]
    }
    %Tesla.Env{status: 200, body: Jason.encode!(result)}
  end

  def build_topics([t0, t1, t2]) do
    t0 =
      if is_nil(t0) do
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
      else
        t0
      end
    t1 =
      if is_nil(t1) do
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e"
      else
        t1
      end
    t2 =
      if is_nil(t2) do
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      else
        t2
      end
    [t0, t1, t2]
  end
end
