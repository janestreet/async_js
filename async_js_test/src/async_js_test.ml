module Expect_test_config = struct
  open Async_kernel
  module IO = Deferred
  open Js_of_ocaml

  external loop_while : (unit -> bool Js.t) Js.callback -> unit = "loop_while"

  let is_in_browser = Js.Optdef.test (Obj.magic Dom_html.document : _ Js.Optdef.t)

  let run =
    if is_in_browser
    then (fun f ->
      Async_js.init ();
      don't_wait_for
        (let%map.Deferred () = f () in
         Bonsai_test_handle_garbage_collector.garbage_collect ()))
    else
      fun f ->
      let result = Monitor.try_with f in
      loop_while
        (Js.wrap_callback (fun () ->
           Async_kernel_scheduler.Expert.run_cycles_until_no_jobs_remain ();
           Js.bool (not (Deferred.is_determined result))));
      Bonsai_test_handle_garbage_collector.garbage_collect ();
      match Deferred.peek result with
      | Some (Ok result) -> result
      | Some (Error exn) -> raise exn
      | None -> assert false
  ;;

  let sanitize s = s
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
end
