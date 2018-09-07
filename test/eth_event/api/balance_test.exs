defmodule EthEvent.Api.BalanceTest do
  use ExUnit.Case, async: false

  alias EthEvent.Api.Balance

  test "build query" do
    address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
    assert {:ok, [^address, "latest"]} =
           Balance.build_query(%Balance{address: address}, [])
    assert {:ok, [^address, "0x1"]} =
           Balance.build_query(%Balance{address: address, block_number: 1}, [])
  end

  test "build result" do
    address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
    assert {:ok, balance} =
           Balance.build_result(%Balance{address: address}, "0x64")
    assert %Balance{
      address: ^address,
      balance: 100,
    } = balance
  end
end
