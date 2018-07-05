defmodule EthEvent.EncodeTest do
  use ExUnit.Case, async: true

  alias EthEvent.Encode
  alias EthEvent.Decode

  test "keccak256 encoding" do
    data = "Transfer(address,address,uint256)"
    sig = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    assert ^sig = Encode.keccak256(data)
  end

  test "encodes quantity when is tag" do
    assert "latest" = Encode.encode(:quantity, "latest")
  end

  test "encodes quantity when is already encoded" do
    assert "0x0" = Encode.encode(:quantity, "0x000")
  end

  test "encodes quantity when has left zero padding" do
    assert "0x1" = Encode.encode(:quantity, "0x00001")
  end

  test "encodes quantity when is integer" do
    assert "0x64" = Encode.encode(:quantity, 100)
  end

  test "encodes array" do
    assert ["0x01", "0x02", "0x03"] =
           Encode.encode({:array, {:uint, 8}}, [1,2,3])
  end

  test "encodes topic" do
    val = "0x0000000000000000000000000000000000000000000000000000000000008001"
    assert ^val = Encode.encode({:topic, {:int, 16}}, -1)
  end

  test "encodes bool" do
    assert "0x01" = Encode.encode(:bool, true)
    assert "0x00" = Encode.encode(:bool, false)
  end

  test "encodes biggest size uint" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000064"
    assert ^data = Encode.encode({:uint, 256}, 100)
  end

  test "encodes smallest size uint" do
    data = "0x64"
    assert ^data= Encode.encode({:uint, 8}, 100)
  end

  test "encodes medium size uint" do
    data = "0x00000000000000000000000000000064"
    assert ^data = Encode.encode({:uint, 128}, 100)
  end

  test "encodes biggest size positive int" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000064"
    assert ^data = Encode.encode({:int, 256}, 100)
  end

  test "encodes biggest size negative int" do
    data = "0x8000000000000000000000000000000000000000000000000000000000000064"
    assert ^data = Encode.encode({:int, 256}, -100)
  end

  test "encodes smallest size positive int" do
    data = "0x01"
    assert ^data = Encode.encode({:int, 8}, 1)
  end

  test "encodes smallest size negative int" do
    data = "0x81"
    assert ^data = Encode.encode({:int, 8}, -1)
  end

  test "encodes medium size positive int" do
    data = "0x00000000000000000000000000000064"
    assert ^data = Encode.encode({:int, 128}, 100)
  end

  test "encodes medium size negative int" do
    data = "0x80000000000000000000000000000064"
    assert ^data = Encode.encode({:int, 128}, -100)
  end

  test "twos complement limits are correct" do
    values = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c",
              "d", "e", "f"]
    for i <- values, j <- values do
      encoded = "0x#{i}#{j}"
      if encoded != "0x80" do
        {[value], nil} = Decode.decode([{:int, 8}], "0x#{i}#{j}")
        assert 128 >= value and value >= -127
        assert ^encoded = Encode.encode({:int, 8}, value)
      end
    end
  end

  test "encodes address" do
    data = "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194"
    assert ^data = Encode.encode(:address, data)
  end

  test "encodes address with zero left padding" do
    data = "0x205dcb8ab93d4a8456731e8fb1bc015cd41194"
    assert "0x00205dcb8ab93d4a8456731e8fb1bc015cd41194" =
           Encode.encode(:address, data)
  end

  test "encodes bytes" do
    data = "0x42"
    assert ^data = Encode.encode({:bytes, 1}, data)
  end

  test "encodes bytes with right padding" do
    data = "0x42"
    expected = data <> "00"
    assert ^expected = Encode.encode({:bytes, 2}, data)
  end

  test "encodes bytes when is a random world" do
    data = "foo"
    assert "0x666f6f00" = Encode.encode({:bytes, 4}, data)
  end
end
