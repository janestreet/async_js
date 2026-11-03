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
          (* The opam release of [uri] has no [Uri.equal__local], so we avoid generating
             equal__local, as we don't actually need it. If this ever becomes an issue, we
             can override the uri package in public-release. *)
          type t = Uri.t option [@@deriving equal__global, sexp]
        end)
  ;;
end

module Versioned_rpc = Async_rpc_kernel.Persistent_connection.Versioned_rpc
