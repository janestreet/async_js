//Provides: deasync
var deasync = {
  loopWhile: (function (f) {
    throw new Error("async_js_test has been linked, but the deasync npm package is not available");
  })
}
if (typeof require !== 'undefined') {
  deasync = require('deasync');
}

//Requires: deasync
//Provides: loop_while
function loop_while(f) {
  deasync.loopWhile(f);
  return 0;
}

//Provides: caml_wasm_suspend_available
function caml_wasm_suspend_available() {
  return +!!globalThis.WebAssembly.Suspending;
};
