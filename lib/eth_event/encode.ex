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

  @typedoc """
  Basic types
  """
  @type basic_type
          :: :bool
           | :address
           | {:uint, integer()}
           | {:int, integer()}
           | {:bytes, integer()}

  @typedoc """
  Payload types
  """
  @type payload_type
          :: :quantity
           | {:array, basic_type}
           | {:topic, basic_type}

  @typedoc """
  Types for encoding.
  """
  @type encode_type :: basic_type() | payload_type()

  ############
  # Public API

  @doc """
  Solidity compliant keccak256 function over a `string`.
  """
  @spec keccak256(binary()) :: binary()
  def keccak256(string) when is_binary(string) do
    base =
      string
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
  @spec encode(encode_type(), term())
          :: {:ok, binary()} | {:ok, [binary()]} | {:error, term()}
  def encode(type, value)

  def encode(:quantity, value) do
    quantity_encode(value)
  end
  def encode(:bool, value) do
    bool_encode(value)
  end
  def encode(:address, value) do
    address_encode(value)
  end
  def encode({:uint, n}, value) do
    uint_encode(n, value)
  end
  def encode({:int, n}, value) do
    int_encode(n, value)
  end
  def encode({:bytes, n}, value) do
    bytes_encode(n, value)
  end
  def encode({:topic, type}, value) do
    topic_encode(type, value)
  end
  def encode({:array, type}, values) do
    array_encode(type, values, [])
  end
  def encode(type, _) do
    {:error, "Unrecognized type #{inspect type}"}
  end

  @doc false
  @spec encode!(encode_type(), term()) :: binary() | [binary()] | no_return
  def encode!(type, value)

  def encode!(type, value) do
    case encode(type, value) do
      {:ok, encoded} ->
        encoded
      {:error, reason} ->
        raise reason
    end
  end

  #########
  # Helpers

  @doc false
  def add_zero_padding(value, size) do
    String.pad_leading(value, size, "0")
  end

  @doc false
  def quantity_encode("latest") do
    {:ok, "latest"}
  end
  def quantity_encode("pending") do
    {:ok, "pending"}
  end
  def quantity_encode("earliest") do
    {:ok, "earliest"}
  end
  def quantity_encode("0x" <> value) do
    case String.trim_leading(value, "0") do
      "" ->
        {:ok, "0x0"}
      trimmed ->
        {:ok, "0x" <> trimmed}
    end
  end
  def quantity_encode(value) when is_integer(value) do
    with {:ok, encoded} <- uint_encode(256, value) do
      quantity_encode(encoded)
    end
  end
  def quantity_encode(value) do
    {:error, "Cannot encode #{inspect value} to quantity"}
  end

  @doc false
  def bool_encode(true) do
    {:ok, "0x01"}
  end
  def bool_encode(false) do
    {:ok, "0x00"}
  end
  def bool_encode(value) do
    {:error, "Cannot encode #{inspect value} to boolean"}
  end

  @doc false
  def address_encode("0x" <> address) do
    address_encode(address)
  end
  def address_encode(address) when is_binary(address) do
    case String.length(address) do
      size when size > 40 ->
        {:error, "Address 0x#{address} is too long"}
      size when size < 40 ->
        {:ok, "0x" <> add_zero_padding(address, 40)}
      _ ->
        {:ok, "0x" <> address}
    end
  end
  def address_encode(address) do
    {:error, "Cannot encode #{inspect address} to address"}
  end

  @doc false
  def uint_encode(n, value) when n > 0 and n <= 256 and is_integer(value) do
    size = Integer.floor_div(n, 4)
    with true <- Integer.mod(n, 8) == 0 do
      encoded =
        value
        |> Integer.to_string(16)
        |> String.reverse()
        |> String.split_at(size)
        |> elem(0)
        |> String.reverse()
        |> String.downcase()
        |> add_zero_padding(size)
      {:ok, "0x" <> encoded}
    else
      _ ->
        {:error, "Cannot encode #{inspect value} to uint#{inspect n}"}
    end
  end
  def uint_encode(n, value) do
    {:error, "Cannot encode #{inspect value} to uint#{inspect n}"}
  end

  @doc false
  def int_encode(n, value) when value < 0 do
    with {:ok, "0x" <> encoded} <- uint_encode(n, -value) do
      twos_complement(:minus, encoded)
    end
  end
  def int_encode(n, value) when value >= 0 do
    with {:ok, "0x" <> encoded}<- uint_encode(n, value) do
      twos_complement(:plus, encoded)
    end
  end

  @doc false
  def twos_complement(:minus, "0" <> rest) do
    {:ok, "0x8" <> rest}
  end
  def twos_complement(:minus, "1" <> rest) do
    {:ok, "0x9" <> rest}
  end
  def twos_complement(:minus, "2" <> rest) do
    {:ok, "0xa" <> rest}
  end
  def twos_complement(:minus, "3" <> rest) do
    {:ok, "0xb" <> rest}
  end
  def twos_complement(:minus, "4" <> rest) do
    {:ok, "0xc" <> rest}
  end
  def twos_complement(:minus, "5" <> rest) do
    {:ok, "0xd" <> rest}
  end
  def twos_complement(:minus, "6" <> rest) do
    {:ok, "0xe" <> rest}
  end
  def twos_complement(:minus, "7" <> rest) do
    {:ok, "0xf" <> rest}
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
    {:ok, "0x" <> value}
  end

  @doc false
  def bytes_encode(n, "0x" <> base = value) do
    with {:ok, _} <- base |> String.downcase() |> Base.decode16(case: :lower) do
      case String.length(base) do
        size when size > 2 * n ->
          {:error, "Bytes#{inspect n} is too long"}
        size when size < 2 * n ->
          encoded =
            base
            |> String.reverse()
            |> add_zero_padding(2 * n)
            |> String.reverse()
          {:ok, "0x" <> encoded}
        _ ->
          {:ok, "0x" <> base}
      end
    else
      :error ->
        encoded = Base.encode16(value, case: :lower)
        bytes_encode(n, "0x" <> encoded)
    end
  end
  def bytes_encode(n, value) when is_binary(value) do
    bytes = Base.encode16(value, case: :lower)
    bytes_encode(n, "0x" <> bytes)
  end
  def bytes_encode(n, value) do
    {:error, "Cannot convert #{inspect value} to bytes#{inspect n}"}
  end

  @doc false
  def topic_encode(type, value) do
    with {:ok, "0x" <> encoded} <- encode(type, value) do
      {:ok, "0x" <> add_zero_padding(encoded, 64)}
    end
  end

  @doc false
  def array_encode(_, [], values) do
    {:ok, Enum.reverse(values)}
  end
  def array_encode(type, [value | values], acc) do
    with {:ok, encoded} <- encode(type, value) do
      array_encode(type, values, [encoded | acc])
    end
  end
  def array_encode(type, values, _) do
    {:error, "Cannot encode #{inspect values} to array of #{inspect type}"}
  end
end
