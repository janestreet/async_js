module Expect_test_config = struct
  open Async_kernel
  module IO = Deferred
  open Js_of_ocaml

  external loop_while : (unit -> bool Js.t) Js.callback -> unit = "loop_while"

  let is_in_node =
    let process = Js.Unsafe.get Js.Unsafe.global (Js.string "process") in
    Js.Optdef.test (process : _ Js.Optdef.t)
  ;;

  external suspend_internal
    :  ((Js.Unsafe.any -> unit) -> unit) Js.callback
    -> 'a
    = "caml_wasm_suspend"

  external suspend_is_available : unit -> bool = "caml_wasm_suspend_available"

  let suspend (type a) (f : (a -> unit) -> unit) : a =
    suspend_internal
      (Js.Unsafe.callback_with_arity 1 (fun resolve ->
         f (fun x -> Js.Unsafe.fun_call resolve [| Js.Unsafe.inject x |])))
  ;;

  let run =
    if is_in_node
    then (
      match Sys.backend_type with
      | Other "wasm_of_ocaml" when suspend_is_available () ->
        fun f ->
          Async_js.init ();
          let x =
            suspend
            @@ fun cont ->
            ignore
              (let%bind x = Monitor.try_with f in
               let () = cont x in
               Deferred.return ()
               : unit Deferred.t)
          in
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

  let sanitize s = s
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
end
