open Core
open Async

let implementation_send_string =
  Rpc.Rpc.implement' Async_js_test_lib.Rpcs.send_string (fun (_ : Rpc.Connection.t) str ->
    print_s [%message "Got request for send_string: " ~_:str];
    str)
;;

let implementation_close_connection =
  Rpc.Rpc.implement' Async_js_test_lib.Rpcs.close_connection (fun conn () ->
    print_s [%message "Got request for close_connection"];
    don't_wait_for
      (let%bind () = Clock.after Time_float.Span.second in
       Rpc.Connection.close
         conn
         ~reason:(Info.of_string "got request to close from client")))
;;

let start_http_server ~http_settings () =
  let implementations = [ implementation_send_string; implementation_close_connection ] in
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations
      ~on_unknown_rpc:`Raise
      ~on_exception:Log_on_background_exn
  in
  let respond _ =
    let open Cohttp_static_handler in
    let assets =
      [ Asset.local
          Asset.Kind.javascript
          (Asset.What_to_serve.embedded ~contents:Embedded_files.main_dot_bc_dot_js)
      ]
    in
    Single_page_handler.create_handler
      Single_page_handler.default
      ~on_unknown_url:`Not_found
      ~assets
  in
  Simple_web_server.create
    ~gzip_behavior:`On_every_request
    ~should_log_hosting_url:true
    ~authorize:Krb_http.Authorize.accept_all
    ~rpc_config:
      (Simple_web_server.Rpc_config.create
         ~implementations
         ~initial_connection_state:(fun _ _ _ conn -> conn))
    http_settings
    respond
;;

let main ~http_settings =
  let%bind web_server = start_http_server ~http_settings () in
  let server = Or_error.ok_exn web_server in
  Simple_web_server.close_finished server
;;

let command =
  Command.async
    ~summary:"Start async-js testing server"
    (let%map.Command http_settings = Http_settings.param () in
     fun () -> main ~http_settings)
;;

let () = Command_unix.run command
