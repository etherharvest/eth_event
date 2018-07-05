defmodule EthEvent.Transport do
  @moduledoc """
  Transport layer for JSON RPC from Ethereum nodes.
  """
  use Tesla, docs: false, only: [:post]

  alias EthEvent.Settings

  plug Tesla.Middleware.BaseUrl, Settings.node_url()
  plug Tesla.Middleware.JSON

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
    data =
      id
      |> base_data(method)
      |> Map.put_new("params", params)

    with {:ok, response} <- post("", data) do
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
  def build_response(%Tesla.Env{body: %{"result" => result}}) do
    {:ok, result}
  end
  def build_response(%Tesla.Env{body: %{"error" => %{"message" => reason}}}) do
    {:error, reason}
  end
  def build_response(_) do
    {:error, "Malformed response"}
  end
end
