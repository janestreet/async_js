//Provides: caml_wasm_make_promising_callback
function caml_wasm_make_promising_callback(invoke, env) {
  var p = WebAssembly.promising(invoke);
  return function () {
    p(env).catch(function (e) {
      // rethrows out of the promise to avoid uncaught promises
      setTimeout(function () { throw e; }, 0);
    });
  };
}

//Provides: caml_promising_callback
//Requires: caml_js_wrap_callback
function caml_promising_callback(f) {
  return caml_js_wrap_callback(f);
}

//Provides: caml_wasm_suspend_available
function caml_wasm_suspend_available() {
  return +!!globalThis.WebAssembly.Suspending;
}
