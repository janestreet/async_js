(module
   (import "js" "caml_wasm_make_promising_callback"
      (func $make_promising (param funcref) (param (ref eq)) (result anyref)))
   (import "js" "caml_wasm_suspend_available"
      (func $suspend_available (param (ref eq)) (result (ref eq))))
   (import "env" "caml_callback_1"
      (func $caml_callback_1 (param (ref eq)) (param (ref eq)) (result (ref eq))))
   (import "env" "wrap" (func $wrap (param anyref) (result (ref eq))))

   (func $invoke (param $f (ref eq)) (result (ref eq))
      (call $caml_callback_1 (local.get $f) (ref.i31 (i32.const 0))))

   (func (export "caml_promising_callback") (param $f (ref eq)) (result (ref eq))
      (call $wrap (call $make_promising (ref.func $invoke) (local.get $f))))

   (export "caml_wasm_suspend_available" (func $suspend_available))
)
