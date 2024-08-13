open! Core
open Bonsai_test_handle_garbage_collector

let%expect_test "Enqueue + garbage collect" =
  register_cleanup (fun () -> print_endline "1");
  register_cleanup (fun () -> print_endline "2");
  register_cleanup (fun () -> print_endline "3");
  [%expect {| |}];
  garbage_collect ();
  [%expect
    {|
    1
    2
    3
    |}]
;;
