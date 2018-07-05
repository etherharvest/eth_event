defmodule EthEvent do
  @moduledoc """
  Aliases basic events.
  """
  defmacro __using__(_) do
    quote do
      alias EthEvent.Api.{Block, Balance}
    end
  end
end
