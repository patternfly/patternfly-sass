// The casper instance is created by grunt-casper when in test mode 
var dest = casper.cli.get('save');
var reference = casper.cli.get('reference');
var actual = casper.cli.get('actual');

var path = require('path');

// Note that Casper uses the PhantomJS 'fs' library and not Node's.
var casper_fs = require('fs');
casper_fs.makeDirectory(dest);

// Must be relative to CasperJS directory
var phantomcss = require('../node_modules/phantomcss/phantomcss.js');
phantomcss.init({
  libraryRoot: './node_modules/phantomcss',
  failedComparisonsRoot: './tests/failures'
});

var referenceFiles = casper_fs.list(path.join('.', reference));

casper.start();

casper.then(function() {
  for (var i = 0; i < referenceFiles.length; i++) {
    var file = referenceFiles[i];
    var a = path.join('.', reference, file);
    var b = path.join('.', actual, file);
    if (casper_fs.isFile(b)) {
      phantomcss.compareFiles(a, b);
    }
    else if (casper_fs.isDirectory(b)) {
      // The file list includes '.' and '..' so we want to ignore those.
    }
    else {
      casper.warn("Can't find file: " + b);
      casper.exit(1);
    }
  }
});

casper.run();
