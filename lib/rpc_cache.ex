#  +----------------------------------------------------------------------
#  | Elixir Rpc [ WE CAN DO IT MORE SIMPLE ]
#  +----------------------------------------------------------------------
#  | Copyright (c) 2025 http://www.bytes.net.cn/ All rights reserved.
#  +----------------------------------------------------------------------
#  | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
#  +---------------------------------------------------------------------
#  | Author: dangyuzhang <develop@bytes.net.cn>
#  +----------------------------------------------------------------------
defmodule Bytes.RpcCache do
  @moduledoc false

  @key __MODULE__

  def init_cache(handles, middlewares) do
    :persistent_term.put(@key, %{
      handles: handles,
      middlewares_asc: middlewares,
      middlewares_desc: Enum.reverse(middlewares)
    })
  end

  def get_module(service) do
    Map.get(:persistent_term.get(@key).handles, service, Bytes.Rpc.DefaultHandle)
  end

  def get_middlewares(:asc),
    do: Map.get(:persistent_term.get(@key), :middlewares_asc, [])

  def get_middlewares(:desc),
    do: Map.get(:persistent_term.get(@key), :middlewares_desc, [])
end
