#include <caml/mlvalues.h>

/* Dummy implementations of javascript primitives that are called when modules are
   initialized (e.g. at the toplevel of [Js_of_ocaml.Js]). These override the weak
   aborting stubs from [jsoo_runtime] so that native test runners that link (but never
   meaningfully run) javascript code can start up. */

CAMLprim value caml_pure_js_expr(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_jsstring_of_string(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_js_get(value u, value v) {
  (void)u;
  (void)v;
  return Val_unit;
}

CAMLprim value caml_js_get_console(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_js_pure_expr(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value loop_while(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_wasm_suspend(value u) {
  (void)u;
  return Val_unit;
}
