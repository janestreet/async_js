open! Core
open! Async_rpc_kernel

module Uri = struct
  module T = struct
    include Uri

    let to_string s = Uri.to_string s
  end

  include T
  include Sexpable.Of_stringable (T)
end

module Rpc = struct
  include Persistent_connection.Rpc

  let create_from_uri = Persistent_connection.Rpc.create ~address:(module Uri)

  let create_from_uri_option =
    Persistent_connection.Rpc.create
      ~address:
        (module struct
          type t = Uri.t option [@@deriving equal, sexp]
        end)
  ;;
end

module Versioned_rpc = Async_rpc_kernel.Persistent_connection.Versioned_rpc
