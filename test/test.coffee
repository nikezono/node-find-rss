# test dependency
path = require 'path'
assert  = require 'assert'
request = require 'request'
nock = require 'nock'

# test framework
finder = require '../lib/find-rss'

titleMatcher = (title) -> title.indexOf('nikezono') > -1 && title.indexOf('Activity') > -1

# test property
body = ""

describe "find-rss", ->

  beforeEach ->
    # build mock-server
    nock('https://example.com')
      .get('/').replyWithFile(200, __dirname + '/documents/sample.html')
      .get('/redirect').reply(301, undefined, { Location: '/'})
      .get('/favicon.ico').reply(200, '')
      .get('/nikezono').replyWithFile(200, __dirname + '/documents/sample.html')
      .get('/nikezono.atom').replyWithFile(200, __dirname + '/documents/sample.atom')
      .get('/no_favicon').replyWithFile(200, __dirname + '/documents/no_favicon.html')
    

  describe "callback:http url", ->

    it "正常系:返り値が配列",(done)->

      finder "https://example.com",(error,candidates)->

        assert.equal error,null
        hasUrl =
          candidates
            .filter (i) -> i.url is "https://example.com/nikezono.atom"
            .length > 0
        assert.ok hasUrl
        done()

    it "正常系:リダイレクト",(done)->

      finder "https://example.com/redirect",(error,candidates)->
        assert.equal error,null
        hasUrl =
          candidates
            .filter (i) -> i.url is "https://example.com/nikezono.atom"
            .length > 0
        assert.ok hasUrl
        done()

    it "正常系:feedを直接読ませる",(done)->

      finder "https://example.com/nikezono.atom",(error,candidates)->
        assert.equal error,null
        hasTitle =
          candidates
            .filter (i) -> titleMatcher(i.title)
            .length > 0
        assert.ok hasTitle
        done()

    it "異常系:URLの接続先が存在しない",(done)->
      @timeout 10000

      finder "http://n.o.t.f.o.u.n.d",(error,candidates)->
        assert.ok error?
        done()

    # Promiseのtest
    it "正常系:Promise形式でfeedを読める",->
      finder "https://example.com/nikezono.atom"
      .then (candidates)->
        hasTitle =
          candidates
            .filter (i) -> titleMatcher(i.title)
            .length > 0
        assert.ok hasTitle

    it "異常系:Promise形式でErrorを取得できる",->
      @timeout 10000

      finder "http://n.o.t.f.o.u.n.d"
      .catch (error)->
        assert.ok error?

  describe "options",->

    it "正常系:faviconを取得しない",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        favicon:false

      finder "https://example.com/no_favicon",(error,candidates)->
        assert.equal error,null
        assert.equal candidates[0].favicon, ''
        done()

    it "正常系:getDetail:Detail:false",(done)->
      @timeout 10000

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:false

      finder "https://example.com",(error,candidates)->
        assert.equal error,null
        hasTitle =
          candidates
            .filter (i) -> i.title is 'atom'
            .length > 0
        assert.ok hasTitle
        done()


    it "正常系:getDetail:Detailを取得する",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:true
      finder "https://example.com",(error,candidates)->
        assert.equal error,null
        hasTitle =
          candidates
            .filter (i) -> titleMatcher(i.title)
            .length > 0
        assert.ok hasTitle
        done()

    it "正常系:getDetail:url/sitenameを補完する",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:true
      finder "https://example.com/nikezono",(error,candidates)->
        assert.equal error,null
        hasUrl =
          candidates
            .filter (i) -> i.url is "https://example.com/nikezono.atom"
            .length > 0
        hasSiteName =
          candidates
            .filter (i) -> i.sitename is "nikezono" # 詳細情報取得時のhtmlのtitleに補完されているか
            .length > 0
        assert.ok hasUrl
        assert.ok hasSiteName
        done()


    it "正常系:getDetail:feedを直接読ませる",(done)->
      @timeout 10000

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:true
      finder "https://example.com/nikezono.atom",(error,candidates)->
        assert.equal error,null
        assert.ok candidates.length > 0
        hasTitle =
          candidates
            .filter (i) -> titleMatcher(i.title)
            .length > 0
        hasUrl =
          candidates
            .filter (i) -> i.url is "https://example.com/nikezono.atom"
            .length > 0
        hasSiteName =
          candidates
            .filter (i) -> titleMatcher(i.sitename) # 同じものが入る
            .length > 0
        assert.ok hasTitle
        assert.ok hasUrl
        assert.ok hasSiteName
        done()


    it "正常系:getDetail:favicon:両方ON",(done)->

      finder = require '../lib/find-rss'
      finder.setOptions
        getDetail:true
        favicon:true
      finder "https://example.com",(error,candidates)->
        assert.equal error,null
        hasUrl =
          candidates
            .filter (i) -> i.url is "https://example.com/nikezono.atom"
            .length > 0
        hasSiteName =
          candidates
            .filter (i) -> i.sitename is "nikezono"
            .length > 0
        hasFavicon =
          candidates
            .filter (i) -> i.favicon is "https://example.com/favicon.ico"
            .length > 0
        assert.ok hasUrl
        assert.ok hasSiteName
        assert.ok hasFavicon
        done()
