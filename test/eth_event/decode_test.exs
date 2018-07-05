defmodule EthEvent.DecodeTest do
  use ExUnit.Case, async: true

  alias EthEvent.Decode

  test "decodes packed arguments" do
    data = "0x97205dcb8ab93d4a8456731e8fb1bc015cd4119464"
    address = "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194"
    value = 100
    assert {[^address, ^value], nil} =
           Decode.decode([:address, {:uint, 8}], data)
  end

  test "decoded boolean" do
    data = "0x01"
    assert {[true], nil} = Decode.decode([:bool], data)
    data = "0x00"
    assert {[false], nil} = Decode.decode([:bool], data)
  end

  test "decodes biggest size uint" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000064"
    assert {[100], nil} = Decode.decode([{:uint, 256}], data)
  end

  test "decodes smallest size uint" do
    data = "0x64"
    assert {[100], nil} = Decode.decode([{:uint, 8}], data)
  end

  test "decodes medium size uint" do
    data = "0x00000000000000000000000000000064"
    assert {[100], nil} = Decode.decode([{:uint, 128}], data)
  end

  test "decodes biggest size positive int" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000064"
    assert {[100], nil} = Decode.decode([{:int, 256}], data)
  end

  test "decodes biggest size negative int" do
    data = "0x8000000000000000000000000000000000000000000000000000000000000064"
    assert {[-100], nil} = Decode.decode([{:int, 256}], data)
  end

  test "decodes smallest size positive int" do
    data = "0x01"
    assert {[1], nil} = Decode.decode([{:int, 8}], data)
  end

  test "decodes smallest size negative int" do
    data = "0x81"
    assert {[-1], nil} = Decode.decode([{:int, 8}], data)
  end

  test "decodes medium size positive int" do
    data = "0x00000000000000000000000000000064"
    assert {[100], nil} = Decode.decode([{:int, 128}], data)
  end

  test "decodes medium size negative int" do
    data = "0x80000000000000000000000000000064"
    assert {[-100], nil} = Decode.decode([{:int, 128}], data)
  end

  test "twos complement limits are correct" do
    values = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a",
              "B", "b", "C", "c", "D", "d", "E", "e", "F", "f"]
    for i <- values, j <- values do
      {[value], nil} = Decode.decode([{:int, 8}], "0x#{i}#{j}")
      assert 128 >= value and value >= -127
    end
  end

  test "decodes address" do
    data = "0x97205dcb8ab93d4a8456731e8fb1bc015cd41194"
    assert {[^data], nil} = Decode.decode([:address], data)
  end

  test "decoded bytes" do
    data = "0x7a013679f78d6b23bdcfcea19bb0baec"
    assert {["0x7a013679f78d6b23bdcfcea19bb0baec"], nil} =
           Decode.decode([{:bytes, 16}], data)
  end

  test "cast with added zero padding" do
    data = "0x81"
    assert {:ok, 129} = Decode.cast({:int, 256}, data)
  end

  test "cast boolean" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000001"
    assert {:ok, true} = Decode.cast(:bool, data)
    data = "0x0000000000000000000000000000000000000000000000000000000000000000"
    assert {:ok, false} = Decode.cast(:bool, data)
  end

  test "cast uint" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000064"
    assert {:ok, 100} = Decode.cast({:uint, 8}, data)
  end

  test "cast positive int" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000001"
    assert {:ok, 1} = Decode.cast({:int, 8}, data)
  end

  test "cast negative int" do
    data = "0x0000000000000000000000000000000000000000000000000000000000000081"
    assert {:ok, -1} = Decode.cast({:int, 8}, data)
  end

  test "cast address" do
    data = "0x000000000000000000000000ca47f4ad7a013679f78d6b23bdcfcea19bb0baec"
    assert {:ok, "0xca47f4ad7a013679f78d6b23bdcfcea19bb0baec"} =
           Decode.cast(:address, data)
  end

  test "cast bytes" do
    data = "0x000000000000000000000000ca47f4ad7a013679f78d6b23bdcfcea19bb0baec"
    assert {:ok, "0x7a013679f78d6b23bdcfcea19bb0baec"} =
           Decode.cast({:bytes, 16}, data)
  end
end
