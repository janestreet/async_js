module Async_js_debug = Debug
open Core
open Async_kernel
open Js_of_ocaml
open! Async_kernel_require_explicit_time_source

module Uri = struct
  include Uri

  let sexp_of_t = Uri_sexp.sexp_of_t
end

module Websocket_connection = struct
  module T = Async_rpc_kernel.Rpc.Connection

  module Close_code : sig
    type t [@@deriving sexp, equal]

    val to_int : t -> int
    val of_event : _ WebSockets.closeEvent Js.t -> t
    val normal_closure : t
  end = struct
    type close_event_code = int [@@deriving compare, sexp, equal]

    let all_of_close_event_code = []

    type t =
      | Normal_closure
      | Going_away
      | Protocol_error
      | Unsupported_data
      | No_status_Received
      | Abnormal_closure
      | Invalid_frame_payload_data
      | Policy_violation
      | Message_too_big
      | Missing_extension
      | Internal_error
      | Service_restart
      | Try_again_later
      | Bad_gateway
      | TLS_handshake
      | Unknown_close_event_code of close_event_code
      | Invalid_close_event_code of close_event_code
    [@@deriving compare, enumerate, sexp, equal]

    let to_int = function
      | Normal_closure -> 1000
      | Going_away -> 1001
      | Protocol_error -> 1002
      | Unsupported_data -> 1003
      | No_status_Received -> 1005
      | Abnormal_closure -> 1006
      | Invalid_frame_payload_data -> 1007
      | Policy_violation -> 1008
      | Message_too_big -> 1009
      | Missing_extension -> 1010
      | Internal_error -> 1011
      | Service_restart -> 1012
      | Try_again_later -> 1013
      | Bad_gateway -> 1014
      | TLS_handshake -> 1015
      | Unknown_close_event_code code -> code
      | Invalid_close_event_code code -> code
    ;;

    let normal_closure = Normal_closure

    let of_int = function
      | 1000 -> Normal_closure
      | 1001 -> Going_away
      | 1002 -> Protocol_error
      | 1003 -> Unsupported_data
      | 1005 -> No_status_Received
      | 1006 -> Abnormal_closure
      | 1007 -> Invalid_frame_payload_data
      | 1008 -> Policy_violation
      | 1009 -> Message_too_big
      | 1010 -> Missing_extension
      | 1011 -> Internal_error
      | 1012 -> Service_restart
      | 1013 -> Try_again_later
      | 1014 -> Bad_gateway
      | 1015 -> TLS_handshake
      | code ->
        if code >= 3000 && code <= 4999
        then Unknown_close_event_code code
        else Invalid_close_event_code code
    ;;

    let of_event close_event = of_int close_event##.code

    let%test_unit "to_int -> of_int round-trip" =
      List.iter all ~f:(fun t -> assert ([%compare.equal: t] (of_int (to_int t)) t))
    ;;
  end

  module Connection_failure = struct
    type t =
      { error : Error.t
      ; close_event : (Close_code.t * string) option
      }
    [@@deriving fields ~getters]

    let create error ~close_event = { error; close_event }
  end

  let close_websocket (websocket : WebSockets.webSocket Js.t) reason =
    (* [close_withCodeAndReason] does nothing if the connection is already Closed. *)
    let close reason =
      (* The code must be either 1000 (Normal_closure), or between 3000 and 4999
         (Unknown_close_event_code). *)
      websocket##close_withCodeAndReason
        Close_code.(to_int normal_closure)
        (Js.string reason)
    in
    match close reason with
    | () -> ()
    | exception (_ : Exn.t) ->
      (* this can fail if [reason] is too long or contains invalid UTF8 *)
      close "close-reason-was-too-long-or-contains-invalid-utf8"
  ;;

  let connect_websocket url ~from_server ~to_server ~time_source ~open_timeout =
    match new%js WebSockets.webSocket (Js.string (Uri.to_string url)) with
    | exception Js_error.Exn exn ->
      (* e.g. SECURITY_ERR, though note that e.g. connecting to ws:// from a https:// page
         in chrome seems to manifest as successful construction but immediate closure (see
         below). *)
      return
        (Error
           (Connection_failure.create
              (Error.of_string (Js_error.message exn))
              ~close_event:None))
    | exception exn ->
      return (Error (Connection_failure.create (Error.of_exn exn) ~close_event:None))
    | websocket ->
      let connected_ivar = Ivar.create () in
      let first_close_event = Set_once.create () in
      let cleanup_after_close ~reason =
        (* [Pipe.close] and [WebSocket.close] are all idempotent. *)
        Pipe.close from_server;
        Pipe.close_read to_server;
        close_websocket websocket reason
      in
      let fail_connect (failure : Connection_failure.t) =
        (* If we haven't connected yet, then connecting just failed. Otherwise it was the
           closure of an existing connection. *)
        Ivar.fill_if_empty connected_ivar (Error failure);
        cleanup_after_close
          ~reason:(Error.to_string_hum (Connection_failure.error failure))
      in
      let onclose (browser_close_event : _ WebSockets.closeEvent Js.t) =
        let close_code = Close_code.of_event browser_close_event in
        let close_reason = Js.to_string browser_close_event##.reason in
        Set_once.set_if_none first_close_event ~here:[%here] (close_code, close_reason);
        (* The RPC API doesn't give us a good place to put details about _why_ the
           connection closed.

           Note that in Chrome the browser close reason is typically empty, and the close
           code doesn't actually provide that much insight into why the connection failed
           (it's available in the inspector console, but as far as I can tell, not
           available to us). So it's not like we're losing much anyway. *)
        let was_connected = Ivar.is_full connected_ivar in
        let reason =
          let what_happened =
            match was_connected with
            | false -> "connection failed"
            | true -> "closed"
          in
          sprintf !"WebSocket %s (%{sexp:Close_code.t})" what_happened close_code
        in
        if was_connected
        then cleanup_after_close ~reason
        else
          fail_connect
            (Connection_failure.create
               (Error.of_string reason)
               ~close_event:(Some (close_code, close_reason)));
        Js._false
      in
      let onmessage (event : _ WebSockets.messageEvent Js.t) =
        let data = Typed_array.Bigstring.of_arrayBuffer event##.data_buffer in
        Pipe.write_without_pushback_if_open from_server data;
        Js._false
      in
      let connected () = Ivar.fill_if_empty connected_ivar (Ok first_close_event) in
      websocket##.binaryType := Js.string "arraybuffer";
      (* if the websocket is already closed, [onclose] won't be re-fired when we add our
         handler. *)
      (match websocket##.readyState with
       | CONNECTING ->
         websocket##.onopen
         := Dom.handler (fun (_ : _ Dom.event Js.t) ->
              connected ();
              Js._false)
       | OPEN -> connected ()
       | CLOSING | CLOSED ->
         (* e.g., Refused to connect to ws: because it violates Content Security Policy *)
         fail_connect
           (Connection_failure.create
              (Error.of_string "WebSocket failed immediately (illegal URI?)")
              ~close_event:None));
      (* Upon an error, [onerror] fires and then [onclose] fires (it's possible for a
         graceful closure to call [onclose] only). Since Async_RPC has no notion of
         graceful closure, we only need to handle [onclose] anyway. Further, the event
         passed to [onerror] contains no extra information about the error. Note that we
         still listen to [onerror] to prevent the error from leaking to uncontrolled
         context *)
      websocket##.onerror
      := Dom.handler (fun (_ : _ Dom.event Js.t) ->
           let permission_hint =
             "WebSocket encountered an unexpected error. Unfortunately, the browser \
              doesn't provide any information about the error. There might be more \
              information in the DevTools network tab"
           in
           Async_js_debug.log_s [%message permission_hint];
           Js._false);
      websocket##.onmessage := Dom.handler onmessage;
      websocket##.onclose := Dom.handler onclose;
      let connected_deferred = Ivar.read connected_ivar in
      don't_wait_for
        (match%bind connected_deferred with
         | Error (_ : Connection_failure.t) -> return ()
         | Ok (_ : (Close_code.t * string) Set_once.t) ->
           Pipe.iter_without_pushback to_server ~f:(fun data ->
             match (websocket##.readyState : WebSockets.readyState) with
             | CONNECTING ->
               raise_s [%message "BUG: onopen called but readyState is CONNECTING"]
             | CLOSING | CLOSED -> ()
             | OPEN ->
               let buffer = Typed_array.Bigstring.to_arrayBuffer data in
               (try websocket##send_buffer buffer with
                | exn ->
                  Error.raise (Error.tag ~tag:"websocket##send_buffer" (Error.of_exn exn)))));
      let cleanup_when_a_pipe_is_closed =
        let%map () =
          Deferred.any_unit [ Pipe.closed to_server; Pipe.closed from_server ]
        in
        cleanup_after_close ~reason:"RPC connection closed by client"
      in
      don't_wait_for cleanup_when_a_pipe_is_closed;
      (match%map
         Time_source.with_timeout
           (Time_source.of_synchronous time_source)
           open_timeout
           connected_deferred
       with
       | `Result result -> result
       | `Timeout ->
         let reason =
           Error.create_s
             [%message
               "Timed out opening WebSocket" (url : Uri.t) (open_timeout : Time_ns.Span.t)]
         in
         let failure = Connection_failure.create reason ~close_event:None in
         fail_connect failure;
         Error failure)
  ;;

  let default_uri () =
    let scheme = if String.equal Url.Current.protocol "https:" then "wss" else "ws" in
    let port =
      match Url.Current.port with
      | Some port -> port
      | None ->
        if String.equal Url.Current.protocol "https:"
        then Url.default_https_port
        else Url.default_http_port
    in
    let host = Url.Current.host in
    Uri.make ~scheme ~host ~port ()
  ;;

  let default_heartbeat_config =
    (* Even though we expect the server to be heartbeating regularly, we have to set a
       long timeout here to prevent RPC timeouts in backgrounded tabs. When a throttled
       tab gets scheduled, the code to check for timeouts runs before the code to process
       incoming heartbeats, and it will otherwise think the server hasn't been
       heartbeating when in fact it just hasn't processed them yet. *)
    Async_rpc_kernel.Rpc.Connection.Heartbeat_config.create
      ~timeout:(Time_ns.Span.of_int_min 5)
      ()
  ;;

  let attempt_connection
    ?(handshake_timeout =
      Async_rpc_kernel.Async_rpc_kernel_private.default_handshake_timeout)
    ?(time_source = Synchronous_time_source.wall_clock ())
    ?heartbeat_timeout_style
    ?description
    ?identification
    ?implementations
    ~uri
    ~heartbeat_config
    ()
    =
    let finish_handshake_by =
      Time_ns.add (Synchronous_time_source.now time_source) handshake_timeout
    in
    let description =
      Info.Portable.create_s
        [%message
          "websocket" (description : (Info.Portable.t option[@sexp.option])) (uri : Uri.t)]
    in
    let make_connection transport ~handshake_timeout =
      let create (T.Client_implementations.T { connection_state; implementations }) =
        let always_provide_rpc_shapes = true in
        T.create
          transport
          ~handshake_timeout
          ~time_source
          ~heartbeat_config
          ?heartbeat_timeout_style
          ?identification
          ~description
          ~implementations
          ~connection_state
          ~provide_rpc_shapes:always_provide_rpc_shapes
      in
      match implementations with
      | None -> create (T.Client_implementations.null ())
      | Some implementations -> create implementations
    in
    let from_server_r, from_server_w = Pipe.create () in
    let to_server_r, to_server_w = Pipe.create () in
    match%bind
      connect_websocket
        uri
        ~from_server:from_server_w
        ~to_server:to_server_r
        ~time_source
        ~open_timeout:handshake_timeout
    with
    | Error failure -> return (Error failure)
    | Ok close_event ->
      let transport =
        Async_rpc_kernel.Pipe_transport.create
          Async_rpc_kernel.Pipe_transport.Kind.bigstring
          from_server_r
          to_server_w
      in
      let handshake_timeout =
        Time_ns.diff finish_handshake_by (Synchronous_time_source.now time_source)
      in
      (match%bind make_connection transport ~handshake_timeout with
       | Ok connection -> return (Ok connection)
       | Error exn ->
         (* For failures that are closed by [onclose], we will always have a [close_event] *)
         let%bind () = Async_rpc_kernel.Rpc.Transport.close transport in
         return
           (Error
              (Connection_failure.create
                 (Error.of_exn exn)
                 ~close_event:(Set_once.get close_event))))
  ;;

  type 'rest client_t =
    ?uri:Uri.t
    -> ?handshake_timeout:Time_ns.Span.t
    -> ?time_source:Synchronous_time_source.t
    -> ?heartbeat_config:T.Heartbeat_config.t
    -> ?heartbeat_timeout_style:T.Heartbeat_timeout_style.t
    -> ?description:Info.Portable.t
    -> ?identification:Bigstring.t
    -> ?implementations:T.Client_implementations.t
    -> 'rest

  let client
    ?(uri = default_uri ())
    ?handshake_timeout
    ?time_source
    ?(heartbeat_config = default_heartbeat_config)
    ?heartbeat_timeout_style
    ?description
    ?identification
    ?implementations
    ()
    =
    [%bind
      match
        attempt_connection
          ?handshake_timeout
          ?time_source
          ?heartbeat_timeout_style
          ?description
          ?identification
          ?implementations
          ~uri
          ~heartbeat_config
          ()
      with
      | Ok connection -> return (Ok connection)
      | Error failure -> return (Error (Connection_failure.error failure))]
  ;;

  let client_exn
    ?uri
    ?handshake_timeout
    ?time_source
    ?heartbeat_config
    ?heartbeat_timeout_style
    ?description
    ?identification
    ?implementations
    ()
    =
    client
      ?uri
      ?handshake_timeout
      ?time_source
      ?heartbeat_config
      ?heartbeat_timeout_style
      ?description
      ?identification
      ?implementations
      ()
    >>| Or_error.ok_exn
  ;;
end

include Async_rpc_kernel.Rpc

module Connection = struct
  include Connection
  include Websocket_connection
end
