/*
 * Usage: phantomjs capture.js [width] [height] [url] [output]
 */

var system = require('system');
var args = system.args;

if (args.length === 5) {
  var width = args[1];
  var height = args[2];
  var url = args[3];
  var output = args[4];
  var page = require('webpage').create();
  page.viewportSize = { width: width, height: height };
  page.settings.resourceTimeout = 2000;
  page.open(url, function(status) {
    if (status == "fail") {
      console.log("Opening " + url + " failed");
      phantom.exit();
    }
    page.evaluate(function() {
      var style = document.createElement('style');
      style.innerHTML = [
        '* {',
        'animation: none !important;',
        'transition: none !important;',
        '-webkit-animation: none !important;',
        '-webkit-transition: none !important;',
        '}'].join('\n');
      document.body.appendChild(style);
    });
    window.setTimeout(function () {
      page.render(output);
      phantom.exit();
    }, 200);
  });
} else {
  console.log("Invalid argument!");
}
