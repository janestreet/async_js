(module
   (import "env" "wrap" (func $wrap (param anyref) (result (ref eq))))
   (import "env" "caml_js_expr"
      (func $caml_js_expr (param (ref eq)) (result (ref eq))))
   (import "env" "caml_js_meth_call"
      (func $caml_js_meth_call
         (param (ref eq)) (param (ref eq)) (param (ref eq)) (result (ref eq))))
   (import "js" "caml_wasm_await"
      (func $await (param anyref) (result (ref eq))))
   (import "js" "caml_wasm_await_available"
      (func $await_available (param (ref eq)) (result (ref eq))))
   (import "env" "unwrap" (func $unwrap (param (ref eq)) (result anyref)))
   (import "env" "current_suspender"
      (global $current_suspender (mut externref)))

   (global $deasync (mut eqref) (ref.null eq))

   (type $block (array (mut (ref eq))))
   (type $string (array (mut i8)))

   (data $deasync "require('deasync')")
   (data $loopWhile "loopWhile")

   (func (export "loop_while") (param $f (ref eq)) (result (ref eq))
      (if (ref.is_null (global.get $deasync))
         (then
            (global.set $deasync
               (call $caml_js_expr
                  (array.new_data $string $deasync
                     (i32.const 0) (i32.const 18))))))
      (drop
         (call $caml_js_meth_call
            (ref.as_non_null (global.get $deasync))
            (array.new_data $string $loopWhile (i32.const 0) (i32.const 9))
            (array.new_fixed $block 2 (ref.i31 (i32.const 0)) (local.get $f))))
      (ref.i31 (i32.const 0)))

   (func (export "caml_wasm_await") (param $f (ref eq)) (result (ref eq))
      (call $await (call $unwrap (local.get $f))))

   (export "caml_wasm_await_available" (func $await_available))
)
