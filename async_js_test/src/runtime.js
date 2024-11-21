//Provides: deasync
var deasync = require('deasync');

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
