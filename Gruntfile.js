/*global module,require*/
var lrSnippet = require('connect-livereload')();

var glob = require('glob');
var path = require('path');
var process = require('process');
var connect = require('connect');

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  // configurable paths
  var projectConfig = {
    src: '',
    dist: 'dist'
  };

  try {
    projectConfig.src = require('./bower.json').appPath || projectConfig.src;
  } catch (e) {}

  var testPath = path.join(projectConfig.src, 'tests', 'patternfly');
  var testFiles = glob.sync(path.join(testPath, '**', '*.html'));
  testFiles = testFiles.map(function(x) { return path.join('patternfly', path.relative(testPath, x)); });

  // If you supply --port, it needs to go before the task name in the command line!  For example:
  // grunt --port=9001 serve
  var port = grunt.option('port') || 9000;

  grunt.initConfig({
    config: projectConfig,
    clean: {
      build: '<%= config.dist %>'
    },
    watch: {
      options: {
        livereload: true
      },
      css: {
        files: 'sass/*.scss',
        tasks: ['sass']
      },
      js: {
        files: 'components/patternfly/dist/js/patternfly.min.js'
      },
      livereload: {
        files: [
          'dist/css/*.css',
          'components/patternfly/tests/*.html',
          'components/patternfly/dist/js/*.js'
        ]
      }
    },
    shell: {
      rake: {
        command: "rake 'convert[<%= branch %>]'"
      }
    },
    clean: {
      rendered: [
        'tests/sass/*.png',
        'tests/reference/*.png',
        'tests/failures/*.png']
    },
    sass: {
      dist: {
        options: {
          style: 'nested'
        },
        files: {
          'dist/css/patternfly.css': 'sass/patternfly.scss'
        }
      }
    },
    cssmin: {
      minify: {
        expand: true,
        cwd: 'dist/css/',
        src: ['*.css', '!*.min.css'],
        dest: 'dist/css/',
        ext: '.min.css'
      }
    },
    casper: {
      reference: {
        options: {
          args: testFiles.concat(["--port=" + port]),
          save: 'tests/reference'
        },
        src: ['tests/render.js']
      },
      sass: {
        options: {
          args: testFiles.concat(["--port=" + port]),
          save: 'tests/sass'
        },
        src: ['tests/render.js']
      },
      compare: {
        options: {
          test: true,
          args: ['--reference=tests/reference', '--sass=tests/sass'],
          save: 'tests/results'
        },
        src: ['tests/compare.js']
      }
    }
  });

  // TODO Make this specific to the shell task
  var branch = grunt.option('branch') || 'master';

  grunt.registerTask('server', [
    'connect:server',
    'watch'
  ]);

  grunt.registerTask('build', [
    'shell',
    'sass',
    'cssmin'
  ]);

  grunt.registerTask('default', ['build']);

  var serveStatic = require('serve-static');
  var serveIndex = require('serve-index');

  grunt.registerTask('serve:reference', 'Serve the reference Patternfly tests.', function(p) {
    app = connect();
    app.use(serveIndex('tests'));
    app.use('/dist', serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'dist')));
    app.use('/components', serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'components')));
    app.use('/patternfly', serveStatic(path.join(projectConfig.src, 'tests', 'patternfly')));

    if (arguments.length == 0) {
      p = port;
    }
    runServer(app, this, p);
  });

  grunt.registerTask('serve:sass', 'Serve the Patternfly tests using Sass CSS.', function() {
    app = connect();
    app.use(serveIndex('tests'));
    app.use('/dist/css', serveStatic(path.join(projectConfig.src, 'dist', 'css')));

    var otherAssets = ['img', 'js', 'fonts'];
    for (var i = 0; i < otherAssets.length; i++) {
      asset = otherAssets[i];
      app.use('/dist/' + asset, serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'dist', asset)));
    }
    app.use('/components', serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'components')));
    app.use('/patternfly', serveStatic(path.join(projectConfig.src, 'tests', 'patternfly')));
    runServer(app, this, port);
  });

  var runServer = function(app, task, p) {
    var keepalive = grunt.option('keepalive') || false;
    var done = task.async();
    require('http').createServer(app).listen(p).on('listening', function() {
      grunt.log.writeln("Started web server on port " + p);
      if (!keepalive) {
        done();
      } else {
        grunt.log.writeln("Listening forever...");
      }
    });
  };

  grunt.registerTask('render:reference', "Render reference images", function(p) {
    if (arguments.length == 0) {
      p = port;
    }
    grunt.task.run('serve:reference:' + p);
    grunt.config('casper.reference.options.args', testFiles.concat(["--port=" + p]));
    grunt.task.run('casper:reference');
  });

  grunt.registerTask('render:sass', ['serve:sass', 'casper:sass']);

  grunt.registerTask('test', "Run tests", function() {
    grunt.task.run('build');
    // We have to do all this stupidity with the ports because I don't know of away to stop a server
    // once it has started, and if we start two servers on the same port, the task will fail.
    //
    // Looks like other people hit the same issue: https://github.com/gruntjs/grunt-contrib-connect/issues/83
    var p = port + 1;
    grunt.task.run('render:reference:' + p);
    grunt.task.run('render:sass');
    grunt.task.run('casper:compare');
  });
};
