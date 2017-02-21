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
      if /(feed)|(atom)|(rdf)|(rss)/.test name
        argumentIsCandidate = true

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

    feedparser.on 'error',(err)->
      # FeedParserの仕様的にerrorは複数回発生するため、error発生時はendをemitして終了させる
      this.emit 'end',err

    feedparser.on 'readable',->
      if candidates.length is 0
        data = this.meta
        candidates.push data

    feedparser.write htmlBody
    feedparser.end (err)->
      return callback err if err
      return callback null,candidates

  else

    for cand in candidates
      cand.sitename = sitename
      cand.favicon  = favicon

    return callback null,candidates