defmodule EthEvent.Encode do
  @moduledoc """

  The available solidity types are:

    - `:quantity` - Unsigned int without left zero padding. Also admits tags.
    - `{:array, type}` - List of values as a specific `type`.
    - `{:topic, type}` - A 32 bits left zero padded encoded value as a specific
      `type`.
    - `:bool` - Boolean type (1 byte).
    - `{:uint, n}` - Unsigned integer of size `n` bits, where `0 < n <= 256`
      and `Integer.mod(n, 8) == 0`.
    - `{:int, n}` - Two's complement integer of size `n` bits, where
      `0 < n <= 256` and `Integer.mod(n, 8) == 0`
    - `:address` - Ethereum address (20 bytes).
    - `{:bytes, n}` - `n` bytes where `0 < n <= 32`.

  ## Encode Elixir types to EVM types

  When given a Elixir type (`integer()` or `binary()`), use the function
  `EthEvent.Encode.encode/2` to ecode it to an EVM compliant type.

  ```
  > EthEvent.Decode.decode({:int, 8}, -1)
  "0x81"
  ```

  The result shows the transformation of `-1` to the EVM's twos complement
  integer encoded value.


  ## Solidity compliant `keccak256`

  ```
  > data = "Transfer(address,address,uint256)"
  > EthEvent.Encode.keccak256(data)

  ```
  """

  alias ExthCrypto.Hash.Keccak

  ############
  # Public API

  @doc """
  Solidity compliant keccak256` function over a `str`.
  """
  def keccak256(str) when is_binary(str) do
    base =
      str
      |> Keccak.kec()
      |> Base.encode16(case: :lower)
    "0x" <> base
  end

  @doc """
  Encodes Elixir types to EVM types. Receives a `type` and a `value` to encode.

  The available solidity types are:

    - `:quantity` - Unsigned int without left zero padding. Also admits tags.
    - `{:array, type}` - List of values as a specific `type`.
    - `{:topic, type}` - A 32 bits left zero padded encoded value as a specific
      `type`.
    - `:bool` - Boolean type (1 byte).
    - `{:uint, n}` - Unsigned integer of size `n` bits, where `0 < n <= 256`
      and `Integer.mod(n, 8) == 0`.
    - `{:int, n}` - Two's complement integer of size `n` bits, where
      `0 < n <= 256` and `Integer.mod(n, 8) == 0`
    - `:address` - Ethereum address (20 bytes).
    - `{:bytes, n}` - `n` bytes where `0 < n <= 32`.
  """
  def encode(type, value) do
    type_encode(type, value)
  end

  #########
  # Helpers

  @doc false
  def type_encode(:quantity, "0x" <> encoded) do
    case String.trim_leading(encoded, "0") do
      "" ->
        "0x0"
      trimmed ->
        "0x" <> trimmed
    end
  end
  def type_encode(:quantity, value) when is_binary(value) do
    value
  end
  def type_encode(:quantity, value) when is_integer(value) do
    case quantity_encode(value) do
      "" ->
        "0x0"
      encoded when is_binary(encoded) ->
        "0x" <> encoded
      error ->
        error
    end
  end
  def type_encode({:array, type}, values) when is_list(values) do
    array_encode(type, values, [])
  end
  def type_encode({:topic, type}, value) do
    with "0x" <> encoded when is_binary(encoded) <- type_encode(type, value) do
      "0x" <> add_zero_padding(encoded, 64)
    end
  end
  def type_encode(:bool, value) when is_boolean(value) do
    with encoded when is_binary(encoded) <- bool_encode(value) do
      "0x" <> encoded
    end
  end
  def type_encode({:uint, n}, value) when is_integer(value) do
    with encoded when is_binary(encoded) <- uint_encode(n, value) do
      "0x" <> encoded
    end
  end
  def type_encode({:int, n}, value) when is_integer(value) do
    with encoded when is_binary(encoded) <- int_encode(n, value) do
      "0x" <> encoded
    end
  end
  def type_encode(:address, "0x" <> value) do
    type_encode(:address, value)
  end
  def type_encode(:address, value) when is_binary(value) do
    with encoded when is_binary(encoded) <- address_encode(value) do
      "0x" <> encoded
    end
  end
  def type_encode({:bytes, n}, "0x" <> value) do
    with encoded when is_binary(encoded) <- bytes_encode(n, value) do
      "0x" <> encoded
    end
  end
  def type_encode({:bytes, n}, value) when is_binary(value) do
    new_value =
      value
      |> Base.encode16()
      |> String.downcase()

    type_encode({:bytes, n}, "0x" <> new_value)
  end
  def type_encode(type, _) do
    {:error, "Unrecognized type #{inspect type}"}
  end

  @doc false
  def array_encode(_, [], values) do
    Enum.reverse(values)
  end
  def array_encode(type, [value | values], acc) do
    with {:error, _} = error <- type_encode(type, value) do
      error
    else
      encoded ->
        array_encode(type, values, [encoded | acc])
    end
  end

  @doc false
  def quantity_encode(value) when is_integer(value) do
    with encoded when is_binary(encoded) <- uint_encode(256, value) do
      String.trim_leading(encoded, "0")
    end
  end

  @doc false
  def bool_encode(true) do
    "01"
  end
  def bool_encode(false) do
    "00"
  end
  def bool_encode(value) do
    {:error, "Invalid value #{inspect value} for boolean"}
  end

  @doc false
  def uint_encode(n, value) when n > 0 and n <= 256 do
    size = Integer.floor_div(n, 4)
    with true <- Integer.mod(n, 8) == 0 do
      value
      |> Integer.to_string(16)
      |> String.reverse()
      |> String.split_at(size)
      |> elem(0)
      |> String.reverse()
      |> String.downcase()
      |> add_zero_padding(size)
    else
      _ ->
        {:error, "Invalid uint#{inspect n}"}
    end
  end
  def uint_encode(n, _) do
    {:error, "Invalid uint#{inspect n}"}
  end

  @doc false
  def add_zero_padding(value, size) do
    current_size = String.length(value)
    if current_size < size do
      String.duplicate("0", size - current_size) <> value
    else
      value
    end
  end

  @doc false
  def int_encode(n, value) when value < 0 do
    with encoded when is_binary(encoded) <- uint_encode(n, -value) do
      twos_complement(:minus, encoded)
    end
  end
  def int_encode(n, value) when value >= 0 do
    with encoded when is_binary(encoded) <- uint_encode(n, value) do
      twos_complement(:plus, encoded)
    end
  end

  @doc false
  def twos_complement(:minus, "0" <> rest) do
    "8" <> rest
  end
  def twos_complement(:minus, "1" <> rest) do
    "9" <> rest
  end
  def twos_complement(:minus, "2" <> rest) do
    "a" <> rest
  end
  def twos_complement(:minus, "3" <> rest) do
    "b" <> rest
  end
  def twos_complement(:minus, "4" <> rest) do
    "c" <> rest
  end
  def twos_complement(:minus, "5" <> rest) do
    "d" <> rest
  end
  def twos_complement(:minus, "6" <> rest) do
    "e" <> rest
  end
  def twos_complement(:minus, "7" <> rest) do
    "f" <> rest
  end
  def twos_complement(_, "8" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "9" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "a" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "b" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "c" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "d" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "e" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(_, "f" <> _) do
    {:error, "Overflow in int"}
  end
  def twos_complement(:plus, value) do
    value
  end

  @doc false
  def address_encode(address) do
    case String.length(address) do
      size when size > 40 ->
        {:error, "Address #{address} is too long"}
      size when size < 40 ->
        add_zero_padding(address, 40)
      _ ->
        address
    end
  end

  @doc false
  def bytes_encode(n, bytes) do
    case String.length(bytes) do
      size when size > 2 * n ->
        {:error, "Bytes#{inspect n} is too long"}
      size when size < 2 * n ->
        bytes
        |> String.reverse()
        |> add_zero_padding(2 * n)
        |> String.reverse()
      _ ->
        bytes
    end
  end
end
