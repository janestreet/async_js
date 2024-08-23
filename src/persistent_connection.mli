open! Core
open Async_kernel

module Rpc : sig
  include
    Async_rpc_kernel.Persistent_connection.S
    with type conn = Rpc.Connection.t
     and type t =
      Persistent_connection_kernel.Make(Async_rpc_kernel.Persistent_connection.Rpc_conn).t

  type 'a create :=
    server_name:string
    -> ?on_event:('a Event.t -> unit Deferred.t)
    -> ?retry_delay:(unit -> Time_ns.Span.t)
    -> ?random_state:[ `Non_random | `State of Random.State.t ]
    -> ?time_source:Time_source.t
    -> connect:('a -> conn Or_error.t Deferred.t)
    -> (unit -> 'a Or_error.t Deferred.t)
    -> t

  val create_from_uri : Uri.t create
  val create_from_uri_option : Uri.t option create
end

module Versioned_rpc :
  Async_rpc_kernel.Persistent_connection.S
  with type conn = Async_rpc_kernel.Versioned_rpc.Connection_with_menu.t
   and type t =
    Persistent_connection_kernel.Make
      (Async_rpc_kernel.Persistent_connection.Versioned_rpc_conn)
    .t
