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
  var testFiles = glob(path.join(testPath, '**', '*.html'), { sync: true }, function(err, files) {
    return files.map(function(x) { return path.join('patternfly', x) });
  });

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
          args: testFiles
        },
        src: ['tests/render.js']
      }
    }
  });

  // TODO Make this specific to the shell task
  var branch = grunt.option('branch') || 'master';
  var port = grunt.option('port') || 9000;

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

  grunt.registerTask('reference', 'Serve the reference Patternfly tests.', function() {
    var keepalive = grunt.option('keepalive') || false;
    var done = this.async();
    app = connect();
    app.use(serveIndex('tests'));
    app.use('/dist', serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'dist')));
    app.use('/components', serveStatic(path.join(projectConfig.src, 'components', 'patternfly', 'components')));
    app.use('/patternfly', serveStatic(path.join(projectConfig.src, 'tests', 'patternfly')));
    app.use('/patternfly/img', serveStatic(path.join(projectConfig.src, 'tests', 'patternfly')));

    require('http').createServer(app).listen(port).on('listening', function() {
      grunt.log.writeln("Started web server on port " + port);
      if (!keepalive) {
        done();
      } else {
        grunt.log.writeln("Listening forever...");
      }
    });
  });

  grunt.registerTask('serve', 'Serve the Patternfly tests using Sass CSS.', function() {
    var keepalive = grunt.option('keepalive') || false;
    var done = this.async();
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
    app.use('/patternfly/img', serveStatic(path.join(projectConfig.src, 'tests', 'patternfly')));

    require('http').createServer(app).listen(port).on('listening', function() {
      grunt.log.writeln("Started web server on port " + port);
      if (!keepalive) {
        done();
      } else {
        grunt.log.writeln("Listening forever...");
      }
    });
  });

  grunt.registerTask('render-reference', ['reference', 'casper:reference']);

  grunt.registerTask('test', [
    'build',
    'reference'
    // TODO create task to render Sass tests.
  ]);
};
