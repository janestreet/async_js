#include <caml/mlvalues.h>

CAMLprim value loop_while(value u) {
  (void)u;
  return Val_unit;
}
