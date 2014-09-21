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
    var destination = path.join(dest, path.basename(test, '.html'));
    this.capture(destination + '.png');
  });
});

casper.run();
