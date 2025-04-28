(module
   (import "env" "wrap" (func $wrap (param anyref) (result (ref eq))))
   (import "env" "caml_js_global"
      (func $caml_js_global (param (ref eq)) (result (ref eq))))
   (import "env" "caml_jsstring_of_string"
      (func $caml_jsstring_of_string (param (ref eq)) (result (ref eq))))
   (import "env" "caml_js_meth_call"
      (func $caml_js_meth_call
         (param (ref eq)) (param (ref eq)) (param (ref eq)) (result (ref eq))))
   (import "bindings" "suspend_fiber"
      (func $suspend (param anyref) (result (ref eq))))
   (import "js" "caml_wasm_suspend_available"
      (func $suspend_available (param (ref eq)) (result (ref eq))))
   (import "env" "unwrap" (func $unwrap (param (ref eq)) (result anyref)))
   (global $deasync (mut eqref) (ref.null eq))
   (type $block (array (mut (ref eq))))
   (type $string (array (mut i8)))

   (data $require "require")
   (data $deasync "deasync")
   (data $loopWhile "loopWhile")

   (func (export "loop_while") (param $f (ref eq)) (result (ref eq))
      (if (ref.is_null (global.get $deasync))
         (then
            (global.set $deasync
               (call $caml_js_meth_call
                  (call $caml_js_global (ref.i31 (i32.const 0)))
                  (array.new_data $string $require (i32.const 0) (i32.const 7))
                  (array.new_fixed $block 2 (ref.i31 (i32.const 0))
                     (call $caml_jsstring_of_string
                        (array.new_data $string $deasync
                           (i32.const 0) (i32.const 7))))))))
      (drop
         (call $caml_js_meth_call
            (ref.as_non_null (global.get $deasync))
            (array.new_data $string $loopWhile (i32.const 0) (i32.const 9))
            (array.new_fixed $block 2 (ref.i31 (i32.const 0)) (local.get $f))))
      (ref.i31 (i32.const 0)))
   (func (export "caml_wasm_suspend") (param $f (ref eq)) (result (ref eq))
      (call $suspend (call $unwrap (local.get $f))))
   (export "caml_wasm_suspend_available" (func $suspend_available)))
