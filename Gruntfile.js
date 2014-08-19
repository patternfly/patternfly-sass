/*global module,require*/
var lrSnippet = require('connect-livereload')();
var mountFolder = function (connect, dir) {
    return connect.static(require('path').resolve(dir));
};

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

  grunt.initConfig({
    config: projectConfig,
    clean: {
      build: '<%= config.dist %>'
    },
    connect: {
      server: {
        options: {
          port: 9000,
          hostname: '0.0.0.0',
          middleware: function (connect) {
            return [
                lrSnippet,
                mountFolder(connect, projectConfig.src),
                mountFolder(connect, projectConfig.src + 'tests')
            ];
          }
        }
      }
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
    sass: {
      dist: {
        options: {
          style: 'compact'
        },
        files: {
          'dist/css/patternfly.css': 'sass/patternfly.scss'
        }
      }
    },
  });

  grunt.loadNpmTasks('grunt-contrib-sass');

  grunt.registerTask('server', [
    'connect:server',
    'watch'
  ]);

  grunt.registerTask('build', [
    'sass',
  ]);

  grunt.registerTask('default', ['build']);
};
