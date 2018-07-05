defmodule EthEvent.Api.BlockTest do
  use ExUnit.Case, async: false

  alias EthEvent.Api.Block

  test "build_query" do
    assert {:ok, ["latest", false]} = Block.build_query(%Block{}, [])
    assert {:ok, [1, false]} = Block.build_query(%Block{block_number: 1}, [])
  end

  test "build result when mined" do
    data = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    timestamp = DateTime.from_unix!(1424182926)
    result = %{
      "number" => "0x64",
      "hash" => data,
      "transactions" => [],
      "timestamp" => "0x54e34e8e"
    }
    assert {:ok, block} = Block.build_result(%Block{}, result)
    assert %Block{
      block_hash: ^data,
      block_number: 100,
      timestamp: ^timestamp,
      type: "mined",
      extra: []
    } = block
  end

  test "build result when pending" do
    timestamp = DateTime.from_unix!(1424182926)
    result = %{
      "timestamp" => "0x54e34e8e",
      "transactions" => []
    }
    assert {:ok, block} = Block.build_result(%Block{}, result)
    assert %Block{
      block_hash: "pending",
      block_number: "pending",
      timestamp: ^timestamp,
      type: "pending",
      extra: []
    } = block
  end

  test "adds block_number" do
    assert %Block{
      block_number: 100
    } = Block.add(%Block{}, :block_number, "0x64")
  end

  test "adds block_hash" do
    data = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    assert %Block{
      block_hash: ^data
    } = Block.add(%Block{}, :block_hash, data)
  end

  test "adds type" do
    assert %Block{
      type: "mined"
    } = Block.add(%Block{}, :type, "mined")
  end
end
