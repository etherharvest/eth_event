defmodule EthEvent.EncodeTest do
  use ExUnit.Case, async: true

  alias EthEvent.Encode
  alias EthEvent.Decode

  describe "keccak256/1" do
    test "keccak256 encoding" do
      data = "Transfer(address,address,uint256)"
      sig = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
      assert ^sig = Encode.keccak256(data)
    end
  end

  describe "quantity encode/2" do
    test "when is latest" do
      assert {:ok, "latest"} = Encode.encode(:quantity, "latest")
    end

    test "when is pending" do
      assert {:ok, "pending"} = Encode.encode(:quantity, "pending")
    end

    test "when is earliest" do
      assert {:ok, "earliest"} = Encode.encode(:quantity, "earliest")
    end

    test "when is hex value" do
      assert {:ok, "0x64"} = Encode.encode(:quantity, "0x64")
    end

    test "when is 0x0" do
      assert {:ok, "0x0"} = Encode.encode(:quantity, "0x0")
    end

    test "when is hex value with leading zeroes" do
      assert {:ok, "0x64"} = Encode.encode(:quantity, "0x00064")
    end

    test "when is integer" do
      assert {:ok, "0x64"} = Encode.encode(:quantity, 100)
    end
  end

  describe "bool encode/2" do
    test "when is true" do
      assert {:ok, "0x01"} = Encode.encode(:bool, true)
    end

    test "when is false" do
      assert {:ok, "0x00"} = Encode.encode(:bool, false)
    end
  end

  describe "address encode/2" do
    test "when is a good address" do
      address = "0xb5A5F22694352C15B00323844aD545ABb2B11028"
      assert {:ok, ^address} = Encode.encode(:address, address)
    end

    test "when is a short address" do
      address = "0x5A5F22694352C15B00323844aD545ABb2B11028"
      expected = "0x05A5F22694352C15B00323844aD545ABb2B11028"
      assert {:ok, ^expected} = Encode.encode(:address, address)
    end
  end

  describe "uint encode/2" do
    test "encodes biggest size uint" do
      data = "0x0000000000000000000000000000000000000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:uint, 256}, 100)
    end

    test "encodes smallest size uint" do
      data = "0x64"
      assert {:ok, ^data} = Encode.encode({:uint, 8}, 100)
    end

    test "encodes medium size uint" do
      data = "0x00000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:uint, 128}, 100)
    end
  end

  describe "int encode/2" do
    test "encodes biggest size positive int" do
      data = "0x0000000000000000000000000000000000000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:int, 256}, 100)
    end

    test "encodes biggest size negative int" do
      data = "0x8000000000000000000000000000000000000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:int, 256}, -100)
    end

    test "encodes smallest size positive int" do
      data = "0x01"
      assert {:ok, ^data} = Encode.encode({:int, 8}, 1)
    end

    test "encodes smallest size negative int" do
      data = "0x81"
      assert {:ok, ^data} = Encode.encode({:int, 8}, -1)
    end

    test "encodes medium size positive int" do
      data = "0x00000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:int, 128}, 100)
    end

    test "encodes medium size negative int" do
      data = "0x80000000000000000000000000000064"
      assert {:ok, ^data} = Encode.encode({:int, 128}, -100)
    end

    test "twos complement limits are correct" do
      values = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c",
                "d", "e", "f"]
      for i <- values, j <- values do
        encoded = "0x#{i}#{j}"
        if encoded != "0x80" do
          {[value], nil} = Decode.decode([{:int, 8}], "0x#{i}#{j}")
          assert 128 >= value and value >= -127
          assert {:ok, ^encoded} = Encode.encode({:int, 8}, value)
        end
      end
    end
  end

  describe "bytes encode/2" do
    test "encodes bytes" do
      data = "0x42"
      assert {:ok, ^data} = Encode.encode({:bytes, 1}, data)
    end

    test "encodes bytes with right padding" do
      data = "0x42"
      expected = data <> "00"
      assert {:ok, ^expected} = Encode.encode({:bytes, 2}, data)
    end

    test "encodes bytes when is a random word" do
      data = "foo"
      assert {:ok, "0x666f6f00"} = Encode.encode({:bytes, 4}, data)
    end
  end

  describe "topic encode/2" do
    test "encodes topic" do
      val = "0x0000000000000000000000000000000000000000000000000000000000008001"
      assert {:ok, ^val} = Encode.encode({:topic, {:int, 16}}, -1)
    end
  end

  describe "array encode/2" do
    test "encodes array" do
      assert {:ok, ["0x01", "0x02", "0x03"]} =
            Encode.encode({:array, {:uint, 8}}, [1,2,3])
    end
  end
end
