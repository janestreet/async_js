open Core
open Async_kernel
open Async_js_test

let () = Async_js.init ()

let%expect_test "sleep" =
  let%bind () = Async_js.sleep 0.1 in
  print_endline "hello";
  [%expect {| hello |}];
  return ()
;;

let%expect_test "ivar" =
  let ivar = Ivar.create () in
  let x =
    let%bind () = Ivar.read ivar in
    print_endline "hello";
    return ()
  in
  Ivar.fill_exn ivar ();
  let%bind () = x in
  [%expect {| hello |}];
  return ()
;;

let%expect_test "rpc" =
  let open Async_rpc_kernel in
  let rpc =
    Rpc.Rpc.create
      ~name:"echo"
      ~version:0
      ~bin_query:[%bin_type_class: string]
      ~bin_response:[%bin_type_class: unit]
      ~include_in_error_count:Only_on_exn
  in
  let to_server = Pipe.create () in
  let to_client = Pipe.create () in
  let one_connection implementations pipe_to pipe_from =
    let transport =
      Pipe_transport.create Pipe_transport.Kind.string (fst pipe_to) (snd pipe_from)
    in
    let%bind conn =
      Rpc.Connection.create ?implementations ~connection_state:(fun _ -> ()) transport
    in
    return (Result.ok_exn conn)
  in
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations:[ Rpc.Rpc.implement' rpc (fun () text -> print_endline text) ]
      ~on_unknown_rpc:`Continue
      ~on_exception:Log_on_background_exn
  in
  don't_wait_for
    (let%bind server_conn = one_connection (Some implementations) to_server to_client in
     Rpc.Connection.close_finished server_conn);
  let%bind client_conn = one_connection None to_client to_server in
  let%bind () = Rpc.Rpc.dispatch_exn rpc client_conn "hello" in
  [%expect {| hello |}];
  let%bind () = Rpc.Rpc.dispatch_exn rpc client_conn "world" in
  [%expect {| world |}];
  return ()
;;

(* The [uncaught_exn] below is intended. Raising from a test used to hang the inline test
   runner. This test raises on purpose to prevent regressions. *)
let%expect_test "raise" =
  let%bind () = return () in
  raise_s [%message "fail!"]
[@@expect.uncaught_exn
  {|
  (monitor.ml.Error fail!
    ("Caught by monitor at file \"lib/async_js_test/src/async_js_test.ml\", line LINE, characters C1-C2"))
  |}]
;;
