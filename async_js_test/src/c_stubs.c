#include <caml/mlvalues.h>

CAMLprim value loop_while(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_wasm_suspend(value u) {
  (void)u;
  return Val_unit;
}

CAMLprim value caml_wasm_suspend_available(value u) {
  (void)u;
  return Val_false;
}
