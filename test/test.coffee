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

    it "正常系:リダイレクト",(done)->

      finder "http://nikezono.com/",(error,candidates)->
        assert.equal error,null
        assert.equal candidates.length,1
        done()

    it "正常系:feedを直接読ませる",(done)->

      finder "http://github.com/nikezono.atom",(error,candidates)->
        assert.equal error,null
        assert.equal candidates.length,1
        assert.equal candidates[0].title, "nikezono's Activity"
        done()

    it "異常系:URLの接続先が存在しない",(done)->

      finder "http://n.o.t.f.o.u.n.d",(error,candidates)->
        assert.ok error?
        done()

  describe "options",->

    it "正常系:faviconを取得しない",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        favicon:false

      # @note:2014/10/14付けでhtmlにfaviconの場所が書いてない
      finder "http://apple.com",(error,candidates)->
        assert.equal error,null
        assert.equal candidates[0].favicon?,false
        done()

    it "正常系:getDetail:Detail:false",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:false

      finder "http://github.com/nikezono",(error,candidates)->
        assert.equal error,null
        assert.equal candidates[0].title,"atom"
        done()


    it "正常系:getDetail:Detailを取得する",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:true
      finder "http://github.com/nikezono",(error,candidates)->
        assert.equal error,null
        assert.equal candidates[0].title,"nikezono's Activity"
        done()


