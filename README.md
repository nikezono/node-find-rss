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




# Simple To Use 2: HTML Text
    # CoffeeScript

    request = require 'request'
    finder = require 'find-rss'

  request "http://nikezono.com",(error,response,body)->
      # Parsing Html And find Atom/RSS Feed Candidates
      finder body,(_error,candidates)->
        return console.error _error if _error
        console.log candidates

        # =>
        # [ { sitename: 'nikezono.com'
            rel: 'alternate',
            type: 'application/atom+xml',
            title: 'RSS',
            href: '/atom.xml',
            favicon: 'http://nikezono.com/favicon.ico',
            url: 'http://nikezono.com/atom.xml' } ]

# Streaming
    # Coffeescript

    request = require 'request'
    finder = require 'find-rss'

    url = "http://nikezono.com/

    request(url).pipe(finder)

    finder.on "readable",(candidate)->
      console.log candidate
      # =>
      # { sitename: 'nikezono.com'
          rel: 'alternate',
          type: 'application/atom+xml',
          title: 'RSS',
          href: '/atom.xml',
          favicon: 'http://nikezono.com/favicon.ico',
          url: 'http://nikezono.com/atom.xml' }

# Promise

    # CoffeeScript

    request = require 'request'
    finder  = require 'find-rss'

    new Promise (resolve,reject)->
      request url,(error,response,body)->
        resolve body
    .finder
    .catch(error)->
      console.error error
    .then(candidates)->
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
    getTitle:false # get `title` property in each atom/rss candidate(default:false)

