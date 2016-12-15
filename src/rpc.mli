open Core_kernel.Std
open Async_kernel.Std
open Async_rpc_kernel.Std

module Client_implementations : sig
  type nonrec 's t =
    { connection_state : Rpc.Connection.t -> 's
    ; implementations  : 's Rpc.Implementations.t
    }

  val null : unit -> unit t
end

type ('a, 's) client_t
  = ?address           : Host_and_port.t (* Default: host and port of the current page *)
  -> ?heartbeat_config : Rpc.Connection.Heartbeat_config.t
  -> ?description      : Info.t
  -> ?implementations  : 's Client_implementations.t
  -> unit
  -> 'a Deferred.t

val client     : (Rpc.Connection.t Or_error.t, 's) client_t
val client_exn : (Rpc.Connection.t           , 's) client_t
