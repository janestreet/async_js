open! Core
open Async_kernel
open Async_js_test

let () = Async_js.init ()

(* Regression tests for a bug in which we allow [Async_js]s [setTimeout] loop to drive the
   async scheduler instead of driving it ourselves within the expect_test config.

   The bug caused these tests to timeout, not because the yield was hanging, but because
   the frequency of the [setTimeout] loop is too slow.

   Interestingly, combining all these tests into one test, and sequencing the yields with
   [bind] does not trigger the bug, since then all the yields go into the scheduler, which
   means the setTimeout loop doesn't need to go through as many iterations.
*)

let%expect_test _ = Async_kernel_scheduler.yield ()
let%expect_test _ = Async_kernel_scheduler.yield ()
let%expect_test _ = Async_kernel_scheduler.yield ()
