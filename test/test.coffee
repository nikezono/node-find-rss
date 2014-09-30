# test dependency
path = require 'path'
assert  = require 'assert'

# test framework
finder = require '../lib/find-rss'

# test Property
nikezono     = "http://github.com/nikezono"
nikezono2    = "http://github.com/nikezono/"
nikezonoAtom = "http://nikezono.com/atom.xml"
shokai       = "http://shokai.org/blog/feed"
apple        = "http://www.apple.com/"
livedoor     = "http://news.livedoor.com/"
nhk          = "http://www.nhk.or.jp"
rdf          = "http://www.asahi.com/information/service/rss.html"



# findRSS
describe "find-rss", ->

  it "エラー処理できる",->
    finder "egergre",(e,candidates)->
      assert.equal candidates,null
      assert.equal e?, true

  it 'github/nikezono' ,(done)->
    finder nikezono,(e,candidates)->
      assert.equal candidates.length,1
      assert.equal e?, false
      done()

  it 'サイト名が保存されている' ,(done)->
    finder apple,(e,candidates)->
      assert.equal candidates[0].sitename, 'Apple'
      assert.equal e?, false
      done()

  it "atomが返せる",(done)->
    finder nikezono,(e,candidates)->
      assert.equal candidates.length,1
      done()

  it "リダイレクト対応",(done)->
    finder nikezono2,(e,candidates)->
      assert.equal candidates.length,1
      done()

  it "複数のRSSを配列にしまえる",(done)->
    finder livedoor,(e,candidates)->
      assert.equal candidates.length>1, true
      done()

  it "faviconがhtmlのlinkタグから取得できる",(done)->
    finder livedoor,(e,candidates)->
      assert.equal candidates[0].favicon?,true
      done()

  it "faviconを自動で探索する", (done)->
    finder apple,(e,candidates)->
      assert.equal candidates[0].favicon,'http://www.apple.com/favicon.ico'
      done()

  it "RSSフィードが指定された場合、それをそのまま返す",(done)->
    finder nikezonoAtom,(e,candidates)->
      assert.equal candidates.length,1
      assert.equal candidates[0].url,nikezonoAtom
      done()

  it "RSS 1.0 / RDF",(done)->
    finder rdf,(e,candidates)->
      assert.ok candidates.length > 0
      done()

  it "開始タグが'rss'でも読める'",(done)->
    finder shokai,(e,candidates)->
      assert.ok candidates.length > 0
      done()

  it "feedのタイトルを正確に取得できる",(done)->
    finder nikezono, (e,candidates)->
      assert.equal candidates[0].title, "nikezono&#39;s Activity"
      done()

  it "feedのタイトルを正確に取得できる2",(done)->
    finder nikezonoAtom,(e,candidates)->
      assert.equal candidates[0].title, "nikezono.net"
      done()
