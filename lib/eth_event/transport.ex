defmodule EthEvent.Transport do
  @moduledoc """
  Transport layer for JSON RPC from Ethereum nodes.
  """
  use Tesla, docs: false, only: [:post]

  alias EthEvent.Settings

  ############
  # Public API

  @doc """
  Execute remote `method` with some optional `parameters`.
  """
  @spec rpc(binary()) :: {:ok, term()} | {:error, term()}
  @spec rpc(binary(), term()) :: {:ok, term()} | {:error, term()}
  def rpc(method, parameters \\ []) do
    make_ref()
    |> :erlang.phash2()
    |> rpc(method, parameters)
  end

  @doc """
  Sends a JSON RPC request to a Ethereum node. Receives an `id`, a `method`
  and a list for method `parameters`.
  """
  @spec rpc(integer(), binary(), term()) :: {:ok, term()} | {:error, term()}
  def rpc(id, method, params) do
    key = Settings.eth_event_node_key()

    data =
      id
      |> base_data(method)
      |> Map.put_new("params", params)

    client = build_client()

    with {:ok, response} <- post(client, key, data) do
      build_response(response)
    end
  end

  #########
  # Helpers

  @doc false
  def base_data(id, method) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => method,
    }
  end

  @doc false
  def build_response(
    %Tesla.Env{status: 200, body: body}
  ) when is_binary(body) do
    with {:ok, decoded} <- Jason.decode(body) do
      build_response(decoded)
    end
  end
  def build_response(%{"result" => result}) do
    {:ok, result}
  end
  def build_response(%{"error" => %{"message" => reason}}) do
    {:error, reason}
  end
  def build_response(_) do
    {:error, "Malformed response"}
  end

  @doc false
  def build_client do
    Tesla.build_client([
      {Tesla.Middleware.BaseUrl, Settings.eth_event_node_url()},
      Tesla.Middleware.JSON
    ])
  end
end
