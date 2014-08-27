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
    casperjs: {
      files: ['tests/casperjs/**/*.js']
    }
  });

  var branch = grunt.option('branch') || 'master';

  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-casperjs');
  grunt.loadNpmTasks('grunt-shell');

  grunt.registerTask('server', [
    'connect:server',
    'watch'
  ]);

  grunt.registerTask('build', [
    'shell',
    'sass',
    'cssmin'
  ]);

  grunt.registerTask('test', [
    'build',
    'casperjs'
  ]);

  grunt.registerTask('default', ['build']);
};
