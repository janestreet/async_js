open! Core

(** This module is intended to be used for garbage collecting bonsai test handles during
    tests. This library need to be its own standalone library so that it can be used by
    different expect test configs (Bonsai_web_test.Expect_test_config) and
    (Async_js_test.Expect_test_config). *)

(** Enqueues a thunk to be run the next time that [garbage_collect] runs. *)
val register_cleanup : (unit -> unit) -> unit

(** Pops all thunks from the queue. *)
val garbage_collect : unit -> unit
