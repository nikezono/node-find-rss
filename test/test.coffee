# test dependency
path = require 'path'
assert  = require 'assert'
request = require 'request'

# test framework
finder = require '../lib/find-rss'

# test property
body = ""

describe "find-rss", ->

  describe "callback:http url", ->


    it "正常系:返り値が配列",(done)->
      finder "http://nikezono.com",(error,candidates)->

        assert.equal error,null
        assert.equal candidates.length,1
        assert.equal candidates[0].url,"http://nikezono.com/atom.xml"
        done()


  describe "callback:html", ->

    it "正常系:返り値が配列",(done)->
      request.get "http://nikezono.com",(e,r,b)->
        finder b,(error,candidates)->

          assert.equal error,null
          assert.equal candidates.length,1
          assert.equal candidates[0].url,"http://nikezono.com/atom.xml"
          done()


  describe "stream",->

  describe "promise",->

  describe "options",->
