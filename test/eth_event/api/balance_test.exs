defmodule EthEvent.Api.BalanceTest do
  use ExUnit.Case, async: false

  import Tesla.Mock

  alias EthEvent.Api.Block
  alias EthEvent.Api.Balance

  describe "query/2" do
    setup do
      mock_global &EthEvent.TestNode.server/1

      :ok
    end

    test "query balance" do
      assert %Balance{} = Balance.query!(address: "0x42")
    end

    test "query balance with block composition" do
      assert %Balance{block_number: block} =
        Block.query!()
        |> Balance.query!(address: "0x42")
      assert not is_nil(block)
    end
  end

  describe "build_query/2" do
    test "builds query" do
      address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      assert {:ok, [^address, "latest"]} =
            Balance.build_query(%Balance{address: address}, [])
      assert {:ok, [^address, "0x1"]} =
            Balance.build_query(%Balance{address: address, block_number: 1}, [])
    end
  end

  describe "build_result/2" do
    test "builds result" do
      address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      assert {:ok, balance} =
            Balance.build_result(%Balance{address: address}, "0x64")
      assert %Balance{
        address: ^address,
        balance: 100,
      } = balance
    end
  end
end
