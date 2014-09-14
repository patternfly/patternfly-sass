var casper = require('casper').create({
  logLevel: 'debug'
});

// FIXME Get the port passed in
var port = casper.cli.options.port;
var host = "http://localhost:" + '9000' + "/";
var path = require('path');

casper.start().each(casper.cli.args, function(self, test) {
  self.thenOpen(host + test, function() {
    var destination = path.join('tmp', path.basename(test, '.html'));
    casper.echo("Rendering " + test);
    this.capture(destination + '.png');
  });
});

casper.run();
