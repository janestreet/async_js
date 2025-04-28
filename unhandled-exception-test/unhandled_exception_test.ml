open! Core
open Async_kernel

let () = Dynamic.set_root Backtrace.elide true

let () =
  Async_js.add_on_unhandled_exn_handler ~f:(fun _ -> print_endline "Handled the error.")
;;

let () = Async_js.init ()

let () =
  don't_wait_for
    (let%bind () = return () in
     let%bind () = failwith "Failed to handle this error." in
     return ())
;;
