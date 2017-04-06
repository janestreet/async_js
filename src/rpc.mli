open Core_kernel
open Async_kernel
open Import

module Any             = Rpc_kernel.Rpc.Any
module Description     = Rpc_kernel.Rpc.Description
module Implementation  = Rpc_kernel.Rpc.Implementation
module Implementations = Rpc_kernel.Rpc.Implementations
module One_way         = Rpc_kernel.Rpc.One_way
module Pipe_rpc        = Rpc_kernel.Rpc.Pipe_rpc
module Rpc             = Rpc_kernel.Rpc.Rpc
module State_rpc       = Rpc_kernel.Rpc.State_rpc

module Pipe_close_reason = Rpc_kernel.Rpc.Pipe_close_reason

module Connection : sig
  include module type of struct include Rpc_kernel.Rpc.Connection end

  type ('a, 's) client_t
    = ?address           : Host_and_port.t (* Default: host and port of the current page *)
    -> ?heartbeat_config : Heartbeat_config.t
    -> ?description      : Info.t
    -> ?implementations  : 's Client_implementations.t
    -> unit
    -> 'a Deferred.t

  val client     : (t Or_error.t, 's) client_t
  val client_exn : (t           , 's) client_t
end
