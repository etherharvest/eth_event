defmodule EthEvent.SchemaTest do
  use ExUnit.Case, async: true

  alias EthEvent.Schema

  ##############
  # Test helpers

  defmodule Transfer do
    use EthEvent.Schema

    event "Transfer" do
      address :from, indexed: true
      address :to, indexed: true
      uint256 :value
    end
  end

  defp build_event(params \\ %{}) do
    %{
      "address" => "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
      "blockHash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
      "blockNumber" => "0x27",
      "data" => "0x0000000000000000000000000000000000000000000000000000000000000064",
      "logIndex" => "0x0",
      "topics" => [
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      ],
      "type" => "mined"
    }
    |> Map.merge(params)
  end

  #######
  # Tests

  describe "get_type/1" do
    test "get_type for bool" do
      assert {:ok, :bool} = Schema.get_type(:bool)
    end

    test "get_type for address" do
      assert {:ok, :address} = Schema.get_type(:address)
    end

    test "get_type for uint" do
      assert {:ok, {:uint, 256}} = Schema.get_type(:uint)
    end

    test "get_type for int" do
      assert {:ok, {:int, 256}} = Schema.get_type(:int)
    end

    test "get_type for uintN" do
      for i <- 1..256, Integer.mod(i, 8) == 0 do
        key = "uint#{inspect i}" |> String.to_atom()
        assert {:ok, {:uint, ^i}} = Schema.get_type(key)
      end
    end

    test "get_type for intN" do
      for i <- 1..256, Integer.mod(i, 8) == 0 do
        key = "int#{inspect i}" |> String.to_atom()
        assert {:ok, {:int, ^i}} = Schema.get_type(key)
      end
    end

    test "get_type for bytesN" do
      for i <- 1..32 do
        key = "bytes#{inspect i}" |> String.to_atom()
        assert {:ok, {:bytes, ^i}} = Schema.get_type(key)
      end
    end
  end

  describe "add_value/3" do
    test "add value function" do
      values = [a: [1]]
      assert [a: [2, 1]] = Schema.add_value(:a, values, 2)
    end
  end

  describe "add_argument/2" do
    test "add argument function" do
      assert [arguments: _] = Schema.add_argument([], 1)
    end
  end

  describe "add_indexed/2" do
    test "add indexed function" do
      assert [indexed: _] = Schema.add_indexed([], 1)
    end
  end

  describe "add_type/2" do
    test "add type function" do
      assert [signature: _] = Schema.add_type([], 1)
    end
  end

  describe "gen_name/3" do
    test "gen name 0 arguments" do
      assert "Event()" = Schema.gen_name("Event", [], [])
    end

    test "gen name 1 argument" do
      assert "Event(bytes8)" = Schema.gen_name("Event", [{:bytes, 8}], [])
    end

    test "gen name more than 1 argument" do
      assert "Approval(address,address,uint256)" =
            Schema.gen_name("Approval", [:address, :address, {:uint, 256}], [])
    end
  end

  describe "event struct" do
    test "struct exists" do
      sig = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

      event = %Transfer{}
      metadata = Map.get(event, :__metadata__)
      assert %{
        id: "Transfer",
        arity: 3,
        name: "Transfer(address,address,uint256)",
        signature: ^sig,
        arguments: [from: :address, to: :address, value: {:uint, 256}],
        indexed: [from: true, to: true, value: false]
      } = metadata
    end
  end

  describe "copy_header/2" do
    test "copy header" do
      base = %{
        address: "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194",
        block_hash: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        block_number: 1,
        index: 1,
        type: "mined"
      }
      assert %Transfer{
        address: "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194",
        block_hash: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        block_number: 1,
        index: 1,
        type: "mined"
      } = Schema.copy_header(Transfer, base)
    end
  end

  describe "add_address/1" do
    test "add address" do
      data = "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194"
      event = %Transfer{address: data}
      assert {:ok, %{"address" => ^data}} = Schema.add_address(event)
    end

    test "add addresses" do
      data = "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194"
      event = %Transfer{address: [data, data]}
      assert {:ok, %{"address" => [^data, ^data]}} =
            Schema.add_address(event)
    end

    test "add address default is none" do
      event = %Transfer{}
      assert {:ok, %{}} = Schema.add_address(event)
    end
  end

  describe "add_from_block/2" do
    test "add from block" do
      opts = [from_block: 100]
      assert {:ok, %{"fromBlock" => "0x64"}} = Schema.add_from_block(%{}, opts)
    end

    test "add from block default is latest" do
      assert {:ok, %{"fromBlock" => "latest"}} = Schema.add_from_block(%{}, [])
    end
  end

  describe "add_to_block/2" do
    test "add to block" do
      opts = [to_block: 100]
      assert {:ok, %{"toBlock" => "0x64"}} = Schema.add_to_block(%{}, opts)
    end

    test "add to block default is latest" do
      assert {:ok, %{"toBlock" => "latest"}} = Schema.add_to_block(%{}, [])
    end
  end

  describe "add_topics/2" do
    test "add_topics" do
      from = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      to = "0x6560813995c81ef86cf850b365bc6817a6cb5bd"
      event = %Transfer{to: to, from: from}
      assert {:ok, %{"topics" => [
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      ]}} = Schema.add_topics(event, %{})
    end
  end

  describe "build_query/2" do
    test "builds an event query" do
      event = %Transfer{
        to: "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      }
      options = [from_block: 0, to_block: 39]
      assert {:ok, query} = Schema.build_query(event, options)
      assert [%{
        "fromBlock" => "0x0",
        "toBlock" => "0x27",
        "topics" => [
          "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
          nil,
          "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e"
        ]
      }] = query
    end
  end

  describe "get_data_types/3" do
    test "get data types" do
      %{
        __metadata__: %{
          arguments: arguments,
          indexed: indexed
        }
      } = %Transfer{}
      assert [{:uint, 256}] = Schema.get_data_types(arguments, indexed, [])
    end
  end

  describe "cast_topics/4" do
    test "cast topics" do
      %{
        __metadata__: %{
          arguments: arguments,
          indexed: indexed
        }
      } = %Transfer{}
      topics = [
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      ]
      assert [
        "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x06560813995c81ef86cf850b365bc6817a6cb5bd"
      ] = Schema.cast_topics(arguments, indexed, topics, [])
    end
  end

  describe "assign_casted/4" do
    test "assign casted for indexed values" do
      %{__metadata__: %{indexed: indexed}} = %Transfer{}
      topics = [
        "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x06560813995c81ef86cf850b365bc6817a6cb5bd"
      ]
      assert %Transfer{
        from: "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        to: "0x06560813995c81ef86cf850b365bc6817a6cb5bd"
      } = Schema.assign_casted(%Transfer{}, indexed, topics, true)
    end

    test "assign casted for non indexed values" do
      %{__metadata__: %{indexed: indexed}} = %Transfer{}
      values = [100]
      assert %Transfer{
        value: 100
      } = Schema.assign_casted(%Transfer{}, indexed, values, false)
    end
  end

  describe "add/3" do
    test "add address to event" do
      address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      assert %Transfer{
        address: ^address
      } = Schema.add(%Transfer{}, :address, address)
    end

    test "add block number to event" do
      block_number = "0x27"
      assert %Transfer{
        block_number: 39
      } = Schema.add(%Transfer{}, :block_number, block_number)
    end

    test "add index to event" do
      index = "0x64"
      assert %Transfer{
        index: 100
      } = Schema.add(%Transfer{}, :index, index)
    end

    test "add type to event" do
      type = "mined"
      assert %Transfer{
        type: "mined"
      } = Schema.add(%Transfer{}, :type, type)
    end

    test "add topics to event" do
      topics = [
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      ]
      assert %Transfer{
        from: "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        to: "0x06560813995c81ef86cf850b365bc6817a6cb5bd"
      } = Schema.add(%Transfer{}, :topics, topics)
    end

    test "add data to event" do
      data = "0x0000000000000000000000000000000000000000000000000000000000000064"
      assert %Transfer{
        value: 100
      } = Schema.add(%Transfer{}, :data, data)
    end
  end

  describe "build_event/1" do
    test "build one result" do
      data = build_event(%{"logIndex" => "0x64"})
      assert event = Schema.do_build_result(%Transfer{}, data)
      assert %Transfer{
        address: "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        block_number: 39,
        index: 100,
        type: "mined",
        from: "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e",
        to: "0x06560813995c81ef86cf850b365bc6817a6cb5bd",
        value: 100
      } = event
    end
  end

  describe "build_result/2" do
    test "build full results ignoring invalid entries" do
      invalid_topics = [
        "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ee",
        "0x0000000000000000000000008ca88e083ec89a8110b722ec46aace1c1d1b260e",
        "0x00000000000000000000000006560813995c81ef86cf850b365bc6817a6cb5bd"
      ]
      data = [
        build_event(),
        build_event(%{"topics" => invalid_topics}),
        build_event(%{"logIndex" => "0x1"})
      ]
      assert {:ok, [e0, e1]} = Schema.build_result(%Transfer{}, data)
      assert e0.index == 0
      assert e1.index == 1
    end
  end
end
