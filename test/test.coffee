# test dependency
path = require 'path'
assert  = require 'assert'

# test framework
finder = require path.resolve('lib','find-rss')

# test Property
shokai   = "http://shokai.org/blog/"
shokai2   = "http://shokai.org/blog"
apple    = "http://www.apple.com/"
livedoor = "http://news.livedoor.com/"

# findRSS
describe "find-rss", ->

  it "エラー処理できる",->
    finder "egergre",(e,candidates)->
      assert.equal candidates,null
      assert.equal e?, true

  it "atomが返せる",(done)->
    finder shokai,(e,candidates)->
      assert.equal candidates.length,1
      done()

  it "リダイレクト対応",(done)->
    finder shokai2,(e,candidates)->
      assert.equal candidates.length,1
      done()
  it "rss/xmlが返せる",(done) ->
    finder apple,(e,candidates)->
      assert.equal candidates?,true
      done()
  it "複数のRSSを配列にしまえる",(done)->
    finder livedoor,(e,candidates)->
      assert.equal candidates.length>1, true
      done()
