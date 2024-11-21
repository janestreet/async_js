//Provides: deasync
var deasync = require('deasync');

//Requires: deasync
//Provides: loop_while
function loop_while(f) {
  deasync.loopWhile(f);
  return 0;
}

//Provides: caml_wasm_await
var caml_wasm_await =
  globalThis.WebAssembly.Suspending
    ?new globalThis.WebAssembly.Suspending((f)=>new globalThis.Promise(f))
    :()=>{throw new Error("JSPI not enabled")};

//Provides: caml_wasm_await_available
function caml_wasm_await_available () {
    return +!!globalThis.WebAssembly.Suspending;
};
