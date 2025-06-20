#  +----------------------------------------------------------------------
#  | Elixir Rpc [ WE CAN DO IT MORE SIMPLE ]
#  +----------------------------------------------------------------------
#  | Copyright (c) 2025 http://www.bytes.net.cn/ All rights reserved.
#  +----------------------------------------------------------------------
#  | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
#  +---------------------------------------------------------------------
#  | Author: dangyuzhang <develop@bytes.net.cn>
#  +----------------------------------------------------------------------
defmodule Bytes.Rpc do
  @moduledoc false
  require Logger

  use GRPC.Server, service: Bytes.Rpc.Route.Service

  alias Bytes.{RpcMiddleware, RpcCache}
  alias Bytes.Rpc.{Response, Request, Context}

  @spec dispatcher(Request.t(), GRPC.Server.Stream.t()) :: Response.t()
  def dispatcher(%Request{} = req, _stream) do
    case RpcMiddleware.process_request(req) do
      {:ok, %Context{meta: %{service: service, cmd: cmd}} = ctx} ->
        handler = RpcCache.get_module(service)

        result =
          try do
            apply(handler, :handle, [ctx])
          rescue
            error ->
              Logger.error("""
              [RpcDispatcher] Exception in #{service}.#{cmd}:
              #{Exception.format(:error, error, __STACKTRACE__)}
              """)

              %Response{code: 500, message: "Internal Server Error"}
          end

        RpcMiddleware.process_response(ctx, result)

      {:error, reason} ->
        Logger.warning("[RpcDispatcher] Middleware rejected request: #{inspect(reason)}")
        %Response{code: 400, message: "Bad Request"}
    end
  end
end
