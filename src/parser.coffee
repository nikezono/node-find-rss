###
#
# parser.coffee
# htmlBodyからRSSの候補を取得する
# ついでにfaviconも取得する
#
###

FeedParser = require('feedparser')
htmlparser = require 'htmlparser2'

module.exports = exports = (htmlBody,callback)->

  candidates = []
  sitename   = ""
  favicon    = ""
  argumentIsCandidate = false
  sitenameFlag        = false

  parser = new htmlparser.Parser(
    onopentag: (name, attr) ->

      # 入力されたtextが既にfeed
      argumentIsCandidate = true if ["feed","rss","atom"].indexOf(name) > -1

      # linkタグの中に以下のtypeを含むものがあれば候補とする
      if(
        name is "link" and
        (
          ['application/rss+xml',
          'application/atom+xml',
          'application/rdf+xml',
          'application/rss',
          'application/atom',
          'application/rdf',
          'text/rss+xml',
          'text/atom+xml',
          'text/rdf+xml',
          'text/rss',
          'text/atom',
          'text/rdf',
          ].indexOf(attr.type) >= 0
        )
      )
        candidates.push attr

      # linkタグの中に以下のfaviconを含むものがあればアイコンにする
      if (
        name is 'link' and
        (
          attr.rel is 'icon' or
          attr.rel is 'shortcut icon' or
          attr.type is 'image/x-icon'
        )
      )
        favicon = attr.href

      # titleタグを取得する
      sitenameFlag = true if name is "title"

    ontext: (text)->
      sitename = text if sitenameFlag

    onclosetag: (name)->
      sitenameFlag = false if name is "title"
  ,
    recognizeCDATA:true
  )

  parser.write htmlBody
  parser.end()

  # 入力されたテキストがfeedである場合
  if argumentIsCandidate

    feedparser = new FeedParser()
    candidates = []

    feedparser.on 'error',(error)->
      return callback error,null

    feedparser.on 'readable',->
      candidates.push this.meta if candidates.length is 0

    feedparser.write htmlBody
    feedparser.end ->
      return callback null,candidates

  else

    for cand in candidates
      cand.sitename = sitename

    return callback null,candidates



