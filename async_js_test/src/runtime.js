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
    (() => {
        try {
            return new globalThis.WebAssembly.Function(
                {parameters:["externref", "anyref"],
                 results:['eqref']},
                (f)=>new globalThis.Promise(f),
                {suspending:'first'})
        } catch(e) {
            return ()=>{throw new Error("JSPI not enabled")}
        }
    })();

//Provides: caml_wasm_await_available
function caml_wasm_await_available () {
    try {
        new globalThis.WebAssembly.Function(
            {parameters:["externref"], results:[]},
            ()=>0,
            {suspending:'first'});
        return 1;
    } catch(e) {
        return 0;
    }
};
