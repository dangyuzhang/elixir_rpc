#  +----------------------------------------------------------------------
#  | Elixir Rpc [ WE CAN DO IT MORE SIMPLE ]
#  +----------------------------------------------------------------------
#  | Copyright (c) 2025 http://www.bytes.net.cn/ All rights reserved.
#  +----------------------------------------------------------------------
#  | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
#  +---------------------------------------------------------------------
#  | Author: dangyuzhang <develop@bytes.net.cn>
#  +----------------------------------------------------------------------
import Config

config :elixir_rpc, Bytes.RpcServer,
  port: 50051,
  handles: %{},
  middlewares: [
    Bytes.Rpc.CodecMiddleware,
    Bytes.Rpc.LoggerMiddleware
  ]

config :elixir_rpc, Bytes.RpcClient,
  port: 50051,
  host: "localhost",
  node: "node1"
