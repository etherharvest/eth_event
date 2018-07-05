# EthEvent

This app is a work in progress

## Queries

This project provides a simple way of querying events and other information
from the Ethereum blockchain.

### Query Solidity events

Solidity events are no more than encoded block logs. They are usually used to
record that something changed in the contract's state. The following contract
declares and `emit`s an event every time someone sends some tokens to other
address:

```
contract SomeToken is ERC20 {
  Transfer(address indexed from, address indexed to, uint value);
...
  function transfer(address to, uint value) {
    ...
    emit Transfer(msg.sender, to, value)
  }
}
```

Using the `EthEvent.Schema` behaviour you can query the events in the form of
Elixir structs. The `Transfer` event defined in the previous contract, could be
defined as follows:

```
defmodule Transfer do
  use EthEvent.Schema

  event "Transfer" do
    address :from, indexed: true
    address :to, indexed: true
    uint :value
  end
end
```

The previously defined  module includes the functions `Transfer.query/1`,
`Transfer.query/2` and a struct definition for the `Transfer` event e.g:

Let's say we want to look for:
  - The `Transfer` event in the contract of address
  `0xd09de8b6b510aecd508a22811398f468e75c8c4d`.
  - Where the tokens where transferred `from` the wallet address
  `0x93ecb3962981e1ba2928297cb09c1932aa2c9c51`.
  - And only between the blocks `0` and `100`.

We would do the following:

```
> contract_address = "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
> from = "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51"
> query = %Transfer{address: contract_address, from: from}
> options = [from_block: 0, to_block: 100]
> Transfer.query(query, options)
{:ok,
  [
    %Transfer{
      ...
      address: "0xd09de8b6b510aecd508a22811398f468e75c8c4d",
      block_number: 42,
      from: "0x93ecb3962981e1ba2928297cb09c1932aa2c9c51",
      to: "0x1e529de18f95ad5a4f41ac5e159fa307d5a85967",
      value: 100
    }
  ]
}
```

The result is the list of events that match the query.

### Query block number

It is possible to query the block number as well using the function
`Block.query/1` e.g:

```
> use EthEvent
> Block.query(%Block{block_number: "latest"})
{:ok,
  %Block{
    ...
    block_number: 42,
    timestamp: #DateTime<...>
  }
}
```

### Query balance

Similarly to the two previous sections, balances are available as well using
the function `query/1` e.g:

```
> use EthEvent
> address = "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
> Balance.query(%Balance{address: address, block_number: "latest"})
{:ok,
  %Balance{
    address: "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
    block_number: 42,
    balance: 100
  }
}
```

The `balance` field is in _wei_.

### Query composability

One important thing is that events are composable, though they only preserve
some fields when composed e.g:

To query the balance of the wallet address
`0xd09de8b6b510aecd508a22811398f468e75c8c4d` for the block 42 there are two
ways of doing it:

Without block hash:

```
> address = "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
> Balance.query(%Balance{address: address})
{:ok,
  %Balance{
    address: "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
    block_number: 42,
    block_hash: nil,
    balance: 100
  }
}
```

or with block hash:

```
> address = "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
> {:ok, block} = Block.query(%Block{block_number: 42})
> Balance.query(%{block | address: address})
{:ok,
  %Balance{
    address: "0xd09de8b6b510aecd508a22811398f468e75c8c4d"
    block_number: 42,
    block_hash: "0x15feeab052b4bd65c8e3a2e3efab391debb9d8b5def6ced89ea772...",
    balance: 100
  }
}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eth_event` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eth_event, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/eth_event](https://hexdocs.pm/eth_event).

