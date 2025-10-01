open Core
open Async_kernel

include module type of struct
  include Async_rpc_kernel.Rpc
end

module Connection : sig
  include module type of struct
    include Connection
  end

  (** This type of client connects to the websocket at the root of some host and port,
      i.e. [ws://<address>/]. *)
  type 'rest client_t =
    ?uri:Uri.t
    -> ?handshake_timeout:Time_ns.Span.t
    -> ?heartbeat_config:Heartbeat_config.t
    -> ?description:Info.t
    -> ?identification:Bigstring.t
    -> ?implementations:Client_implementations.t
    -> 'rest

  val client : (unit -> t Deferred.Or_error.t) client_t
  val client_exn : (unit -> t Deferred.t) client_t
end
