module Expect_test_config = struct
  open Async_kernel
  module IO = Deferred
  open Js_of_ocaml

  external loop_while : (unit -> bool Js.t) Js.callback -> unit = "loop_while"

  let is_in_node () =
    let process = Js.Unsafe.get Js.Unsafe.global (Js.string "process") in
    Js.Optdef.test (process : _ Js.Optdef.t)
  ;;

  external suspend_internal
    :  ((Js.Unsafe.any -> unit) -> unit) Js.callback
    -> 'a
    = "caml_wasm_suspend"

  let suspend (type a) (f : (a -> unit) -> unit) : a =
    suspend_internal
      (Js.Unsafe.callback_with_arity 1 (fun resolve ->
         f (fun x -> Js.Unsafe.fun_call resolve [| Js.Unsafe.inject x |])))
  ;;

  let run_native f =
    let result = Monitor.try_with f in
    Async_kernel_scheduler.Expert.run_cycles_until_no_jobs_remain ();
    Bonsai_test_handle_garbage_collector.garbage_collect ();
    match Deferred.peek result with
    | Some (Ok result) -> result
    | Some (Error exn) -> raise exn
    | None -> failwith "Async_js_test: test did not stabilize"
  ;;

  let run_js () =
    if is_in_node ()
    then (
      match Sys.backend_type with
      | Other "wasm_of_ocaml" when Async_js.For_async_js_test.suspend_is_available () ->
        fun f ->
          Async_js.init ();
          (* Start the test body here rather than inside [suspend]'s promise executor:
             this runs on pure wasm frames (under the promising [_initialize] entry
             point), so the body may perform OCaml effects, and it matches the deasync
             runner below, which also starts the body synchronously. Inside the executor
             there would be JS frames on the stack, and any effect would fail with
             [SuspendError: trying to suspend JS frames]. *)
          let result = Monitor.try_with f in
          (* Suspend only to wait for the result; the async scheduler keeps running via
             [Async_js]'s (promising) timeout callbacks while we are suspended. *)
          let x = suspend @@ fun cont -> Deferred.upon result cont in
          Bonsai_test_handle_garbage_collector.garbage_collect ();
          (match x with
           | Ok result -> result
           | Error exn -> raise exn)
      | _ ->
        fun f ->
          let result = Monitor.try_with f in
          loop_while
            (Js.wrap_callback (fun () ->
               Async_kernel_scheduler.Expert.run_cycles_until_no_jobs_remain ();
               Js.bool (not (Deferred.is_determined result))));
          Bonsai_test_handle_garbage_collector.garbage_collect ();
          (match Deferred.peek result with
           | Some (Ok result) -> result
           | Some (Error exn) -> raise exn
           | None -> assert false))
    else
      fun f ->
      Async_js.init ();
      don't_wait_for
        (let%map.Deferred () = f () in
         Bonsai_test_handle_garbage_collector.garbage_collect ())
  ;;

  let run =
    match Sys.backend_type with
    | Other ("js_of_ocaml" | "wasm_of_ocaml") -> run_js ()
    | Native | Bytecode | Other _ -> run_native
  ;;

  let sanitize s = s
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
  let trailing_output_syntax = `Attribute
end
