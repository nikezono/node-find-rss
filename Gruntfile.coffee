'use strict'

module.exports = (grunt) ->

  _ = require 'underscore'
  require 'coffee-errors'

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-istanbul'
  grunt.loadNpmTasks 'grunt-notify'

  grunt.registerTask 'test',     [ 'coffeelint','coffee:multiple', 'mochaTest:spec' ]
  grunt.registerTask 'coverage', [ 'clean','copy', 'instrument', 'mochaTest:coverage', 'storeCoverage', 'makeReport']
  grunt.registerTask 'travis',   [ 'test','coverage']
  grunt.registerTask 'default',  [ 'test', 'watch' ]

  grunt.initConfig

    coffeelint:
      options:
        max_line_length:
          value: 100
        indentation:
          value: 2
        newlines_after_classes:
          level: 'error'
        no_empty_param_list:
          level: 'error'
        no_unnecessary_fat_arrows:
          level: 'ignore'
      dist:
        files: [
          { expand: yes, cwd: 'test/', src: [ '*.coffee' ] }
          { expand: yes, cwd: './', src: [ '*.coffee' ] }
          { expand: yes, cwd: 'models/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'config/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'events/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'src/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'public/', src: [ '**/*.coffee' ] }
        ]

    watch:
      options:
        interrupt: yes
      dist:
        files: [
          '*.coffee'
          'models/**/*.coffee'
          'events/**/*.coffee'
          'config/**/*.coffee'
          'src/**/*.coffee'
          'public/**/*.{coffee,js,jade}'
          'test/**/*.coffee'
        ]
        tasks: [ 'coffeelint','coffee','mochaTest:spec' ]

    coffee:
      multiple:
        expand:true
        cwd:'src'
        src:'*.coffee'
        dest:'lib/'
        ext:'.js'
      test:
        expand:true
        cwd:'test'
        src:'*.coffee'
        dest:'coverage/test/'
        ext:'.js'
      test_lib:
        expand:true
        cwd:'src'
        src:'*.coffee'
        dest:'coverage/lib/'
        ext:'.js'

    copy:
      coverage:
        files: [
          expand: true
          src: ['test/*']
          dest: 'coverage/instrument/'
        ]

    clean:
      coverage:
        src: ['coverage/']

    # Istanbul(MochaTest+Coverage Report)
    instrument:
      files: "lib/*.js"
      options:
        lazy: true
        basePath: "coverage/instrument/"

    mochaTest:
      spec:
        options:
          reporter:"spec"
          timeout: 50000
          colors: true
        src: ['test/**/*.coffee']
      coverage:
        options:
          reporter:"spec"
          timeout: 50000
          colors:true
        src: ['coverage/instrument/test/*.coffee']

    storeCoverage:
      options:
        dir: "coverage/reports"

    makeReport:
      src: "coverage/reports/**/*.json"
      options:
        type: "lcov"
        dir: "coverage/reports"
        print: "detail"
