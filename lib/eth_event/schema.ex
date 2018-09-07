defmodule EthEvent.Schema do
  @moduledoc """
  Behaviour to define Solidity like events e.g:

  In Solidity you would declare an event as:

  ```
  Transfer(address indexed from, address indexed to, uint value)
  ```

  Using this library, you would do the equivalent as follows:
  ```
  defmodule Transfer do
    use EthEvent.Schema

    event "Transfer" do
      address :from
      address :to
      uint :value
    end
  end
  ```

  Then is possible to query the `Transfer(address,address,uint256)` event as
  follows:

  ```
  > {:ok, results} = Transfer.query(%Transfer{}, [from_block: 0, to_block: 100])
  ```

  By default the options `Keyword` list is `[]` and `from_block` and `to_block`
  are set to `"latest"`.

  In order to filter the results, the `indexed` fields can be used:

  ```
  > Transfer.query(%Transfer{from: "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51"})
  ```

  The previous query would search for all the `Transfer`s events from the
  address `"0x93ecb3962981e1ba2928297cb09c1932aa2c9c51"` in the `"latest"`
  block.

  In essence the queries will return a list of the following struct:

  ```
  %Transfer{
    address: "0xd09de8b6b510aecd508a22811398f468e75c8c4d", # Contract address
    block_hash: "0x15feeab052b4bd65c8e3a2e3efab391debb9d8b5def6ced89ea7727f26790bd8",
    block_number: 42,
    index: 0, # Index of the log in the block
    type: "mined",
    ...
    from: "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51",
    to: "0x1e529de18f95ad5a4f41ac5e159fa307d5a85967",
    value: 100
  }
  ```
  """

  alias EthEvent.Encode
  alias EthEvent.Decode

  @type t :: struct

  @doc """
  Callback to do the appropriate modifications to the query parameters to
  request an `event` with a list of `options`.
  """
  @callback build_query(
    event :: t(),
    options :: list()
  ) :: {:ok, {t(), map()}} | {:error, term()}

  @doc """
  Callback to build a `result` from an defined `event`.
  """
  @callback build_result(event :: t(), result :: term()) ::
    {:ok, t()} |
    {:error, term()}

  @doc """
  Adds the necessary macros and functions to define an Ethereum event. Receives
  a list of `options`. The only option available is :method and expects a string
  with the JSON RPC call name for the Ethereum node API e.g:

  ```
  defmodule Balance do
    use EthEvent.Schema, method: "eth_getBalance"

    event "Balance" do
      address :address
    end

    (...)
  end
  ```
  """
  defmacro __using__(options) do
    method = Keyword.get(options, :method, "eth_getLogs")
    quote do
      import EthEvent.Schema, only: [event: 2]
      @behaviour EthEvent.Schema
      alias EthEvent.Schema
      alias EthEvent.Transport

      def __method__ do
        unquote(method)
      end

      def build_query(event, options) do
        Schema.build_query(event, options)
      end

      def build_result(event, result) do
        Schema.build_result(event, result)
      end

      def query(event, options \\ []) do
        new_event = Schema.copy_header(__MODULE__, event)
        with {:ok, query} <- build_query(new_event, options),
             {:ok, result} <- Transport.rpc(__method__(), query) do
          build_result(new_event, result)
        end
      end

      defoverridable [build_query: 2, build_result: 2]
    end
  end

  ############
  # Public API

  @doc """
  Copies the header of an `event` to the `module` `event`.
  """
  @spec copy_header(module(), t()) :: t()
  def copy_header(module, event)

  def copy_header(
    module,
    %{address: address,
      block_hash: block_hash,
      block_number: block_number,
      index: index,
      type: type}
  ) do
    header = [
      address: address,
      block_hash: block_hash,
      block_number: block_number,
      index: index,
      type: type
    ]
    struct(module, header)
  end

  @doc """
  Build the `parameters` for an Ethereum `event`.

  The available options are:
    - `from_block` - Block number from which it will search for logs of the
      event. Defaults to `"latest"`.
    - `to_block` - Block number until it will search for logs of the event.
      Defaults to `"latest"`.

  To look for specific topics, add them as values for the indexed arguments in
  the event struct.
  """
  @spec build_query(t(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def build_query(event, options)

  def build_query(event, options) do
    with {:ok, parameters} <- add_address(event),
         {:ok, new_parameters} <- add_from_block(parameters, options),
         {:ok, new_parameters} <- add_to_block(new_parameters, options),
         {:ok, new_parameters} <- add_topics(event, new_parameters) do
      {:ok, [new_parameters]}
    end
  end

  @doc """
  Builds the `results` as an `event`.
  """
  @spec build_result(t(), term()) :: {:ok, t()} | {:error, term()}
  def build_result(event, results)

  def build_result(event, results) do
    build_result(event, results, [])
  end

  @doc false
  def build_result(_, [], acc) do
    {:ok, Enum.reverse(acc)}
  end
  def build_result(event, [result | results], acc) do
    case do_build_result(event, result) do
      nil ->
        build_result(event, results, acc)
      result ->
        build_result(event, results, [result | acc])
    end
  end

  @doc false
  def do_build_result(
    %{__struct__: module},
    %{"address" => address,
      "blockHash" => block_hash,
      "blockNumber" => block_number,
      "data" => data,
      "logIndex" => index,
      "topics" => topics,
    }
  ) do
    module
    |> struct([])
    |> add(:topics, topics)
    |> add(:data, data)
    |> add(:address, address)
    |> add(:block_hash, block_hash)
    |> add(:block_number, block_number)
    |> add(:index, index)
    |> add(:type, (if block_number == "pending", do: "pending", else: "mined"))
  end

  @doc false
  def add(nil, _, _) do
    nil
  end
  def add(event, :address, address) do
    with {:ok, value} <- Decode.cast(:address, address) do
      %{event | address: value}
    end
  end
  def add(event, :block_hash, block_hash) do
    %{event | block_hash: block_hash}
  end
  def add(event, :block_number, block_number) do
    with {:ok, value} <- Decode.cast({:uint, 256}, block_number) do
      %{event | block_number: value}
    end
  end
  def add(event, :index, index) do
    with {:ok, value} <- Decode.cast({:uint, 256}, index) do
      %{event | index: value}
    end
  end
  def add(event, :type, type) do
    %{event | type: type}
  end
  def add(
    %{
      __metadata__: %{
        signature: signature,
        arguments: arguments,
        indexed: indexed
      }
    } = event,
    :topics,
    [signature | topics]
  ) do
    topics = cast_topics(arguments, indexed, topics, [])
    assign_casted(event, indexed, topics, true)
  end
  def add(
    %{__metadata__: %{arguments: arguments, indexed: indexed}} = event,
    :data,
    data
  ) do
    types = get_data_types(arguments, indexed, [])
    with {values, nil} <- Decode.decode(types, data) do
      assign_casted(event, indexed, values, false)
    end
  end
  def add(_, _, _) do
    nil
  end

  @doc false
  def cast_topics([], [], [], acc) do
    Enum.reverse(acc)
  end
  def cast_topics(
    [{key, _} | arguments],
    [{key, false} | indexed],
    topics,
    acc
  ) do
    cast_topics(arguments, indexed, topics, acc)
  end
  def cast_topics(
    [{key, type} | arguments],
    [{key, true} | indexed],
    [topic | topics],
    acc
  ) do
    with {:ok, value} <- Decode.cast(type, topic) do
      cast_topics(arguments, indexed, topics, [value | acc])
    end
  end

  @doc false
  def get_data_types([], [], acc) do
    Enum.reverse(acc)
  end
  def get_data_types(
    [{key, type} | arguments],
    [{key, false} | indexed],
    acc
  ) do
    get_data_types(arguments, indexed, [type | acc])
  end
  def get_data_types(
    [{key, _} | arguments],
    [{key, true} | indexed],
    acc
  ) do
    get_data_types(arguments, indexed, acc)
  end

  @doc false
  def assign_casted(event, [], [], _) do
    event
  end
  def assign_casted(
    event,
    [{key, true} | indexed],
    [value | values],
    true
  ) do
    new_event = Map.put(event, key, value)
    assign_casted(new_event, indexed, values, true)
  end
  def assign_casted(
    event,
    [{key, false} | indexed],
    [value | values],
    false
  ) do
    new_event = Map.put(event, key, value)
    assign_casted(new_event, indexed, values, true)
  end
  def assign_casted(
    event,
    [_ | indexed],
    values,
    type
  ) do
    assign_casted(event, indexed, values, type)
  end

  #########
  # Helpers

  @doc false
  def add_address(%{address: nil}) do
    {:ok, %{}}
  end
  def add_address(%{address: addresses}) when is_list(addresses) do
    with {:ok, values} <- Encode.encode({:array, :address}, addresses) do
      {:ok, %{"address" => values}}
    end
  end
  def add_address(%{address: "0x" <> _ = address}) do
    with {:ok, value} <- Encode.encode(:address, address) do
      {:ok, %{"address" => value}}
    end
  end
  def add_address(event) do
    {:error, "Invalid event #{inspect event}"}
  end

  @doc false
  def add_from_block(params, options) do
    case Keyword.get(options, :from_block, "latest") do
      nil ->
        {:ok, params}
      from_block ->
        with {:ok, value} <- Encode.encode(:quantity, from_block) do
          {:ok, Map.put_new(params, "fromBlock", value)}
        end
    end
  end

  @doc false
  def add_to_block(params, options) do
    case Keyword.get(options, :to_block, "latest") do
      nil ->
        {:ok, params}
      to_block ->
        with {:ok, value} <- Encode.encode(:quantity, to_block) do
          {:ok, Map.put_new(params, "toBlock", value)}
        end
    end
  end

  @doc false
  def add_topics(%{__metadata__: metadata} = event, params) do
    topics = [Map.get(metadata, :signature)]
    indexed = Map.get(metadata, :indexed, [])
    arguments = Map.get(metadata, :arguments, [])

    with {:ok, topics} <- add_topics(indexed, arguments, event, topics) do
      {:ok, Map.put_new(params, "topics", topics)}
    end
  end

  @doc false
  def add_topics([], [], _, topics) do
    {:ok, Enum.reverse(topics)}
  end
  def add_topics(
    [{key, false} | indexed],
    [{key, _} | arguments],
    event,
    topics
  ) do
    add_topics(indexed, arguments, event, topics)
  end
  def add_topics(
    [{key, true} | indexed],
    [{key, type} | arguments],
    event,
    topics
  ) do
    case Map.get(event, key) do
      nil ->
        add_topics(indexed, arguments, event, [nil | topics])
      value ->
        with {:ok, encoded} <- Encode.encode({:topic, type}, value) do
          add_topics(indexed, arguments, event, [encoded | topics])
        end
    end
  end

  ###############
  # Public macros

  @doc """
  Receives the `name` of the event and the definition `block`. Accepts
  `bool/1`, `address/1`, `uint/1`, `int/1`, `uint<M>/1` and `int<M>` where
  `0 < <M> <= 256` and `Integer.mod(<M>, 8) == 0`, and `bytes<N>` where
  `0 < <N> <= 32`.

  ```
  event "Approval" do
    address :owner, indexed: true
    address :spender, indexed: true
    uint :amount
  end
  ```
  """
  defmacro event(name, do: block) do
    spec = expand(block, [name: name])
    quote do
      Module.register_attribute(__MODULE__, :eth_event, accumulate: true)
      EthEvent.Schema.__event__(__MODULE__, unquote(name), unquote(spec))
      Module.eval_quoted(__ENV__, [EthEvent.Schema.__defstruct__(@eth_event)])
    end
  end

  ###############
  # Macro Helpers

  @doc false
  def expand({:__block__, _, stmts}, spec) do
    Enum.reduce(stmts, spec, &(expand(&1, &2)))
  end
  def expand({key, _, [:address | _]}, _) do
    raise ArgumentError, ":address is reserved. Use other name for #{key}"
  end
  def expand({key, _, [:block_number | _]}, _) do
    raise ArgumentError, ":block_number is reserved. Use other name for #{key}"
  end
  def expand({key, _, [:index | _]}, _) do
    raise ArgumentError, ":index is reserved. Use other name for #{key}"
  end
  def expand({key, _, [:type | _]}, _) do
    raise ArgumentError, ":type is reserved. Use other name for #{key}"
  end
  def expand(
    {key, _, [name]},
    spec
  ) when is_atom(name) and is_atom(key) do
    expand(key, name, false, spec)
  end
  def expand(
    {key, _, [name | [opts]]},
    spec
  ) when is_atom(name) and is_atom(key) do
      indexed = Keyword.get(opts, :indexed, false)
      expand(key, name, indexed, spec)
  end
  def expand(_, spec) do
    spec
  end

  @doc false
  def expand(key, name, indexed, spec) do
    with {:ok, type} <- get_type(key) do
      spec
      |> add_argument({name, type})
      |> add_indexed({name, indexed})
      |> add_type(type)
    else
      {:error, reason} ->
        message = "Type error for key #{key} and name #{name}: #{reason}"
        raise ArgumentError, message
    end
  end

  @doc false
  def add_argument(spec, value) do
    add_value(:arguments, spec, value)
  end

  @doc false
  def add_indexed(spec, value) do
    add_value(:indexed, spec, value)
  end

  @doc false
  def add_type(spec, type) do
    add_value(:signature, spec, type)
  end

  @doc false
  def add_value(key, spec, value) do
    {values, spec} = Keyword.pop(spec, key, [])
    Keyword.put_new(spec, key, [value | values])
  end

  @doc false
  def get_type(:bool) do
    {:ok, :bool}
  end
  def get_type(:address) do
    {:ok, :address}
  end
  def get_type(:uint) do
    {:ok, {:uint, 256}}
  end
  def get_type(:int) do
    {:ok, {:int, 256}}
  end
  def get_type(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> get_type()
  end
  def get_type("uint" <> number) do
    with {n, ""} <- Integer.parse(number),
         true <- 0 < n and n <= 256 and Integer.mod(n, 8) == 0 do
      {:ok, {:uint, n}}
    else
      false ->
        reason = "number of bits is invalid (0 < n <= 256 and n % 8 == 0)"
        {:error, reason}
      _ ->
        get_type(nil)
    end
  end
  def get_type("int" <> number) do
    with {n, ""} <- Integer.parse(number),
         true <- 0 < n and n <= 256 and Integer.mod(n, 8) == 0 do
      {:ok, {:int, n}}
    else
      false ->
        reason = "number of bits is invalid (0 < n <= 256 and n % 8 == 0)"
        {:error, reason}
      _ ->
        get_type(nil)
    end
  end
  def get_type("bytes" <> number) do
    with {n, ""} <- Integer.parse(number),
         true <- 0 < n and n <= 32 do
      {:ok, {:bytes, n}}
    else
      false ->
        reason = "number of bytes is invalid (0 < n <= 32)"
        {:error, reason}
      _ ->
        get_type(nil)
    end
  end
  def get_type(_) do
    {:error, "Invalid type"}
  end

  @doc false
  def __event__(module, name, spec) do
    arguments = spec |> Keyword.get(:arguments, []) |> Enum.reverse()
    indexed = spec |> Keyword.get(:indexed, []) |> Enum.reverse()
    signature = spec |> Keyword.get(:signature, []) |> Enum.reverse()

    new_name = gen_name(name, signature, [])
    new_signature = Encode.keccak256(new_name)

    new_spec = [
      id: name,
      arity: length(arguments),
      name: new_name,
      signature: new_signature,
      arguments: arguments,
      indexed: indexed
    ]
    Module.put_attribute(module, :eth_event, new_spec)
  end

  @doc false
  def gen_name(name, [], acc) do
    acc =
      acc
      |> Enum.reverse()
      |> Enum.join(",")
    "#{name}(#{acc})"
  end
  def gen_name(name, [:bool | rest], acc) do
    type = "bool"
    gen_name(name, rest, [type | acc])
  end
  def gen_name(name, [:address | rest], acc) do
    type = "address"
    gen_name(name, rest, [type | acc])
  end
  def gen_name(name, [{:uint, n} | rest], acc) do
    type = "uint#{inspect n}"
    gen_name(name, rest, [type | acc])
  end
  def gen_name(name, [{:int, n} | rest], acc) do
    type = "int#{inspect n}"
    gen_name(name, rest, [type | acc])
  end
  def gen_name(name, [{:bytes, n} | rest], acc) do
    type = "bytes#{inspect n}"
    gen_name(name, rest, [type | acc])
  end

  @doc false
  def __defstruct__([event]) do
    map = event |> Enum.into(%{}) |> Macro.escape()
    keys = event |> Keyword.get(:arguments) |> Keyword.keys()

    quote do
      defstruct [
        {:__metadata__, unquote(map)},
        :address,
        :block_hash,
        :block_number,
        :index,
        :type,
        :extra |
        unquote(keys)
      ]
    end
  end
end
