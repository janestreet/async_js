module Expect_test_config = struct
  open Async_kernel
  module IO = Deferred
  open Js_of_ocaml

  external loop_while : (unit -> bool Js.t) Js.callback -> unit = "loop_while"

  let run f =
    let result = Monitor.try_with f in
    loop_while
      (Js.wrap_callback (fun () ->
         Async_kernel_scheduler.Expert.run_cycles_until_no_jobs_remain ();
         Js.bool (not (Deferred.is_determined result))));
    match Deferred.peek result with
    | Some (Ok result) -> result
    | Some (Error exn) -> raise exn
    | None -> assert false
  ;;

  let sanitize s = s
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
end
