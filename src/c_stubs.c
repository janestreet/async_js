#include <caml/mlvalues.h>

CAMLprim value caml_promising_callback(value f) { return f; }

CAMLprim value caml_wasm_suspend_available(value u) {
  (void)u;
  return Val_false;
}
