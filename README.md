node-find-rss [![Build Status](https://travis-ci.org/nikezono/node-find-rss.png)](https://travis-ci.org/nikezono/node-find-rss)
---

[![NPM](https://nodei.co/npm/find-rss.png)](https://nodei.co/npm/find-rss/)

A module for finding RSS/ATOM feeds, from HTML or URL.

##install

    $ npm install find-rss

# Simple To Use: HTTP Address

    # CoffeeScript
    finder  = require 'find-rss'
    finder "http://nikezono.com"
    .then (candidates)->
      console.log candidates

      # =>
      # [ { sitename: 'nikezono.com'
          rel: 'alternate',
          type: 'application/atom+xml',
          title: 'RSS',
          href: '/atom.xml',
          favicon: 'http://nikezono.com/favicon.ico',
          url: 'http://nikezono.com/atom.xml' } ]

    # CoffeeScript(callback)

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
      maxResponseSize:1000*1000*10 # set http response size limit, e.g. 10MB(dafault:null)

