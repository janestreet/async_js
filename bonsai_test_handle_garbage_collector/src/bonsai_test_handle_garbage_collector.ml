open! Core

let garbage_collection_queue : (unit -> unit) Queue.t = Queue.create ()

let garbage_collect : unit -> unit =
  fun () ->
  Queue.iter garbage_collection_queue ~f:(fun f -> f ());
  let rec loop () =
    match Queue.is_empty garbage_collection_queue with
    | true -> ()
    | false ->
      Queue.dequeue_and_ignore_exn garbage_collection_queue;
      loop ()
  in
  loop ()
;;

let register_cleanup : (unit -> unit) -> unit =
  fun f -> Queue.enqueue garbage_collection_queue f
;;
