module Expect_test_config = struct
  open Async_kernel
  module IO = Deferred
  open Js_of_ocaml

  external loop_while : (unit -> bool Js.t) Js.callback -> unit = "loop_while"

  let run f =
    let result = f () in
    loop_while
      (Js.wrap_callback (fun () -> Js.bool (not (Deferred.is_determined result))));
    match Deferred.peek result with
    | Some result -> result
    | None -> assert false
  ;;

  let sanitize s = s
  let flushed () = true
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
end
