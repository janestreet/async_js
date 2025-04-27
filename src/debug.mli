open Core
open Js_of_ocaml

(** Output a [Sexp.t] value to the console, e.g. via the message extensions:
    {[
      log_s [%message "An example" (of_using : Ppx_message.t)]
    ]} *)
val log_s : Sexp.t -> unit

(** [log_s_as_string] logs the sexp as a string instead of as a JavaScript object, so that
    it appears fully expanded in the console. *)
val log_s_as_string : Sexp.t -> unit

(** Convert a sexp expression into a JavaScript object. This can be used to output OCaml
    values to the console. *)
val any_of_sexp : Sexp.t -> Js.Unsafe.any
