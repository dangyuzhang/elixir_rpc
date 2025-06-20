#  +----------------------------------------------------------------------
#  | Elixir Rpc [ WE CAN DO IT MORE SIMPLE ]
#  +----------------------------------------------------------------------
#  | Copyright (c) 2025 http://www.bytes.net.cn/ All rights reserved.
#  +----------------------------------------------------------------------
#  | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
#  +---------------------------------------------------------------------
#  | Author: dangyuzhang <develop@bytes.net.cn>
#  +----------------------------------------------------------------------
defmodule Bytes.Rpc.CodecMiddleware do
  @behaviour Bytes.Rpc.Middleware
  require Logger
  alias Bytes.Rpc.{Context, Request, Response, Json}

  @spec pre(any()) :: {:ok, map()} | {:error, any()}
  def pre(%Request{meta: %{service: s, cmd: c, node: node}, header: h, body: payload}) do
    with {:ok, cmd} <- parse_atom(c),
         {:ok, service} <- parse_atom(s),
         {:ok, body} <- Json.decode(payload),
         {:ok, headers} <- Json.decode(h) do
      {:ok,
       %Context{meta: %{service: service, cmd: cmd, node: node}, headers: headers, body: body}}
    else
      {:error, reason} ->
        Logger.error("[rpc] decode failed for #{inspect(c)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def pre(_), do: {:error, :invalid_format}

  @spec post(map(), any()) :: Response.t()
  def post(_ctx, %Response{} = resp), do: resp

  def post(_ctx, {:ok, data}) do
    %Response{code: 0, data: Json.encode(data)}
  end

  def post(_ctx, {:error, reason}) do
    %Response{code: 1, message: to_string(reason)}
  end

  defp parse_atom(str) when is_binary(str), do: {:ok, String.to_atom(str)}
  defp parse_atom(atom) when is_atom(atom), do: {:ok, atom}
  defp parse_atom(_), do: {:error, :invalid_atom}
end
