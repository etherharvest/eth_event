defmodule EthEvent.Decode do
  @moduledoc """
  Module with the basic functions to decode event's data.

  The available types are:

    - `:bool` - Boolean type (1 byte).
    - `{:uint, n}` - Unsigned integer of size `n` bits, where `0 < n <= 256`
      and `Integer.mod(n, 8) == 0`.
    - `{:int, n}` - Two's complement integer of size `n` bits, where
      `0 < n <= 256` and `Integer.mod(n, 8) == 0`
    - `:address` - Ethereum address (20 bytes).
    - `{:bytes, n}` - `n` bytes where `0 < n <= 32`.

  ## Decode packed values

  When given a string with packed data, use the function
  `EthEvent.Decode.decode/2` to decode it to the correct types e.g:

  ```
  > data = "0x6481"
  > types = [{:uint, 8}, {:int, 8}]
  > EthEvent.Decode.decode(types, data)
  {[100, -1], nil}
  ```

  The `data` contains two numbers `0x64` as `uint8` (decimal `100`) and `0x81`
  as `int8` (decimal `-1`).

  ## Cast values

  When given a string, use the function `EthEvent.Decode.cast/2` to cast the
  data to the correct type e.g:

  ```
  > data = "0x0000000000000000000000000000000000000000000000000000000000000081"
  > EthEvent.Decode.cast({:int, 8}, data)
  {:ok, -1}
  ```

  The function ignores the zero padding and converts `0x81` to the decimal
  `-1`.
  """

  @type eth_type ::
  :bool |
  {:uint, integer()} |
  {:int, integer()} |
  :address |
  {:bytes, integer()}

  @type eth_types :: list(eth_type())

  @type eth_encoded :: binary()

  @doc """
  Decodes `data` according to a list of `types`.

  ```
  > data = "0x6481"
  > types = [{:uint, 8}, {:int, 8}]
  > EthEvent.Decode.decode(types, data)
  {[100, -1], nil}
  ```
  """
  @spec decode(eth_types(), eth_encoded()) :: {list(), term()} | :error
  def decode(types, data)

  def decode(types, "0x" <> data) do
    decode(types, data, [])
  end
  def decode(_, _) do
    :error
  end

  @doc """
  Casts a `value` to the given `type`.

  ```
  > data = "0x0000000000000000000000000000000000000000000000000000000000000081"
  > EthEvent.Decode.cast({:int, 8}, data)
  {:ok, -1}
  ```
  """
  @spec cast(eth_type(), eth_encoded()) :: {:ok, term()} | :error
  def cast(type, value)

  def cast(type, "0x" <> value) do
    with {:ok, new_value} <- truncate(type, value),
         {new_value, ""} <- type_decode(type, new_value) do
      {:ok, new_value}
    end
  end

  ##################
  # Decoding helpers

  @doc false
  def decode([], "", acc) do
    new_acc = Enum.reverse(acc)
    {new_acc, nil}
  end
  def decode([], data, acc) when is_binary(data) do
    new_acc = Enum.reverse(acc)
    {new_acc, "0x" <> data}
  end
  def decode([type | types], data, acc) do
    with {decoded, rest} <- type_decode(type, data) do
      decode(types, rest, [decoded | acc])
    end
  end

  @doc false
  def type_decode(type, "0x" <> data) do
    type_decode(type, data)
  end
  def type_decode(:bool, data) do
    bool_decode(data)
  end
  def type_decode({:uint, n}, data) do
    uint_decode(n, data)
  end
  def type_decode({:int, n}, data) do
    int_decode(n, data)
  end
  def type_decode(:address, data) do
    address_decode(data)
  end
  def type_decode({:bytes, n}, data) do
    bytes_decode(n, data)
  end
  def type_decode(_, _) do
    :error
  end

  @doc false
  def bool_decode(data) do
    case uint_decode(8, data) do
      {0, rest} ->
        {false, rest}
      {1, rest} ->
        {true, rest}
      _ ->
        :error
    end
  end

  @doc false
  def uint_decode(n, data) when n > 0 and n <= 256 do
    with true <- Integer.mod(n, 8) == 0,
         size = Integer.floor_div(n, 4),
         {extracted, rest} <- String.split_at(data, size),
         true <- String.length(extracted) == size,
         {value, ""} <- Integer.parse(extracted, 16) do
      {value, rest}
    else
      _ ->
        :error
    end
  end

  @doc false
  def int_decode(n, data) when n > 0 and n <= 256 do
    with true <- Integer.mod(n, 8) == 0,
         size = Integer.floor_div(n, 4),
         {extracted, rest} <- String.split_at(data, size),
         true <- String.length(extracted) == size,
         {value, ""} <- twos_complement(extracted) do
      {value, rest}
    else
      _ ->
        :error
    end
  end

  @doc false
  def twos_complement("0" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("1" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("2" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("3" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("4" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("5" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("6" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("7" <> _ = extracted) do
    Integer.parse(extracted, 16)
  end
  def twos_complement("8" <> rest) do
    Integer.parse("-" <> rest, 16)
  end
  def twos_complement("9" <> rest) do
    Integer.parse("-1" <> rest, 16)
  end
  def twos_complement("a" <> rest) do
    Integer.parse("-2" <> rest, 16)
  end
  def twos_complement("b" <> rest) do
    Integer.parse("-3" <> rest, 16)
  end
  def twos_complement("c" <> rest) do
    Integer.parse("-4" <> rest, 16)
  end
  def twos_complement("d" <> rest) do
    Integer.parse("-5" <> rest, 16)
  end
  def twos_complement("e" <> rest) do
    Integer.parse("-6" <> rest, 16)
  end
  def twos_complement("f" <> rest) do
    Integer.parse("-7" <> rest, 16)
  end
  def twos_complement(extracted) do
    extracted
    |> String.downcase()
    |> twos_complement()
  end

  @doc false
  def address_decode(data) do
    size = 40
    with {value, rest} <- String.split_at(data, size),
         true <- String.length(value) == size do
      {"0x" <> value, rest}
    else
      _ ->
        :error
    end
  end

  @doc false
  def bytes_decode(n, data) do
    size = 2 * n
    with true <- 0 < size and size <= 32,
         {value, rest} <- String.split_at(data, size),
         true <- String.length(value) == size do
      {"0x" <> value, rest}
    end
  end

  #################
  # Casting helpers

  @doc false
  def truncate(type, "0x" <> value) do
    {:ok, "0x" <> truncate(type, value)}
  end
  def truncate(:bool, value) do
    do_truncate(value, 2)
  end
  def truncate({:uint, n}, value) when n > 0 and n <= 256 do
    size = Integer.floor_div(n, 4)
    do_truncate(value, size)
  end
  def truncate({:int, n}, value) when n > 0 and n <= 256 do
    truncate({:uint, n}, value)
  end
  def truncate(:address, value) do
    do_truncate(value, 40)
  end
  def truncate({:bytes, n}, value) when n > 0 and n <= 32 do
    do_truncate(value, 2 * n)
  end
  def truncate(_, _) do
    :error
  end

  @doc false
  def do_truncate(value, size) do
    new_value =
      value
      |> String.reverse()
      |> String.split_at(size)
      |> elem(0)
      |> String.reverse()
      |> add_zero_padding(size)
    {:ok, new_value}
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
end
