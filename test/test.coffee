# test dependency
path = require 'path'
assert  = require 'assert'

# test framework
finder = require '../lib/find-rss'

# test Property
nikezono     = "http://github.com/nikezono"
nikezono2    = "http://github.com/nikezono/"
nikezonoAtom = "http://github.com/nikezono.atom"
apple        = "http://www.apple.com/"
livedoor     = "http://news.livedoor.com/"
nhk          = "http://www.nhk.or.jp"


# findRSS
describe "find-rss", ->

  it "エラー処理できる",->
    finder "egergre",(e,candidates)->
      assert.equal candidates,null
      assert.equal e?, true
###
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

  it "文字化けしない", (done)->
    finder livedoor,(e,candidates)->
      #テストできない
      done()
###
