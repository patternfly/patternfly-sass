var casper = require('casper').create({
  logLevel: 'debug',
  onLoadError: function(self, m) {
    self.warn('CAN NOT LOAD ' + m);
    self.exit(1);
  },
  exitOnError: true
});

var port = casper.cli.get('port');
var dest = casper.cli.get('save');
var host = "http://localhost:" + port + "/";
var path = require('path');

// Note that Casper uses the PhantomJS 'fs' library and not Node's.
var casper_fs = require('fs');

casper_fs.makeDirectory(dest);

// TODO need to test on different viewport sizes
casper.start().each(casper.cli.args, function(self, test) {
  self.thenOpen(host + test, function() {
    // Disable animations so we don't get jitter in the image comparisons.
    // Cribbed from phantomcss's turnOffAnimations and
    // http://codeutopia.net/blog/2014/02/05/tips-for-taking-screenshots-with-phantomjs-casperjs/
    this.evaluate(function() {
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
    var destination = path.join(dest, path.basename(test, '.html'));
    this.capture(destination + '.png');
  });
});

casper.run();
