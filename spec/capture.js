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
  var retries = 3;
  page.viewportSize = { width: width, height: height };
  page.settings.resourceTimeout = 2000;
  page.open(url, function() {
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

    window.setInterval(function () {
      if (document.readyState === "complete") {
        page.render(output);
        phantom.exit();
      } else {
        if (retries == 0) phantom.exit();
        retries--;
      }
    }, 200);

  });
} else {
  console.log("Invalid argument!");
}
