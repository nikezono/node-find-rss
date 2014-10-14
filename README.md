node-find-rss [![Build Status](https://travis-ci.org/nikezono/node-find-rss.png)](https://travis-ci.org/nikezono/node-find-rss)[![Test Coverage](https://codeclimate.com/github/nikezono/node-find-rss/badges/coverage.svg)](https://codeclimate.com/github/nikezono/node-find-rss)[![Code Climate](https://codeclimate.com/github/nikezono/node-find-rss/badges/gpa.svg)](https://codeclimate.com/github/nikezono/node-find-rss)
---

[![NPM](https://nodei.co/npm/find-rss.png)](https://nodei.co/npm/find-rss/)

RSS/Atom feed URL Candidates finder

wrapper of [htmlparser2](https://github.com/fb55/htmlparser2)

##install

***using npm:***

    npm install find-rss

***using package.json:***

    "find-rss": "*"

# Simple To Use: HTTP Address

    # CoffeeScript

    finder  = require 'find-rss'
    finder "http://nikezono.com",(error,response,body)->
      return console.error error if error
      console.log candidates

      # =>
      # [ { sitename: 'nikezono.com'
          rel: 'alternate',
          type: 'application/atom+xml',
          title: 'RSS',
          href: '/atom.xml',
          favicon: 'http://nikezono.com/favicon.ico',
          url: 'http://nikezono.com/atom.xml' } ]

# Options

  finder = require 'find-rss'
  finder.setOptions
    favicon:true # find favicon url(default:true)
    getDetail:false # get detail property in each atom/rss candidate(default:false)

