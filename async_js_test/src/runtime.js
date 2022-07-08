//Provides: deasync
var deasync = require('deasync');

//Requires: deasync
//Provides: loop_while
function loop_while(f) {
  deasync.loopWhile(f);
  return 0;
}
