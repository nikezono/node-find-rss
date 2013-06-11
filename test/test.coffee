# test dependency
path = require 'path'
_    = require 'underscore'

# test framework
finder = require path.resolve('lib','find-rss')

# findRSS
finder "http://www.apple.com/",(candidates)->
  console.log candidates
finder "http://news.livedoor.com/",(candidates)->
  console.log candidates