# dependency
htmlparser = require("htmlparser2")
jschardet  = require("jschardet")
iconv      = require 'iconv'

# utility
async        = require 'async'
url          = require 'url'
request      = require 'request'

module.exports = (req,callback)->

  # instance property
  candidates   = []
  sitename     = ''
  sitenameFlag = false
  favicon      = ''
  feedTitle    = ''
  argumentIsCandidate = false

  parser = new htmlparser.Parser(
    onopentag: (name, attr) ->

      argumentIsCandidate = true if ["feed","rss","atom"].indexOf(name) > -1
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
      if (
        name is 'link' and
        (
          attr.rel is 'icon' or
          attr.rel is 'shortcut icon' or
          attr.type is 'image/x-icon'
        )
      )
        favicon = attr.href
      if name is "title"
        sitenameFlag = true

    ontext: (text)->
      feedTitle = text if sitename is '' and argumentIsCandidate
      sitename = text if sitenameFlag


    onclosetag: (name)->
      sitenameFlag = false if name is "title"
  ,
    recognizeCDATA:true
  )

  # main
  urlObject = url.parse req
  requestAndEncodeWithDetectCharset req,(err,body)->
    return callback err,null if err

    # HTMLParser
    parser.write body
    parser.end()

    async.series [(cb)->
      # リクエストされたURLが既にRSSフィードと思われる場合
      if argumentIsCandidate
        candidates = [
          title:feedTitle
          sitename:req
          url:req
          href:req
        ]
        cb()

      # 候補となるURL配列が取得できた場合
      else
        async.forEach candidates,(cand,_cb)->
          cand.sitename = sitename

          # url(フルパス)
          if cand.href.match /[http|https]:\/\//
            cand.url = cand.href
          else
            cand.url = "#{urlObject.protocol}//#{urlObject.host}#{cand.href}"

          # リクエストしてタイトルを取得する
          requestAndEncodeWithDetectCharset cand.url,(err,body)->
            return _cb() if err

            innerFeedTitle = ''
            isFeed = false
            titleFlag = false

            innerParser = new htmlparser.Parser
              onopentag: (name, attr) ->
                isFeed = true if ["feed","rss","atom"].indexOf(name) > -1
                titleFlag = true if name is "title"

              ontext: (text)->
                innerFeedTitle ||= text if titleFlag and isFeed

              onclosetag:(name) ->
                titleFlag = false if name is "title"
            ,
              recognizeCDATA:true

            innerParser.write body
            innerParser.end()

            cand.title = unescape innerFeedTitle

            return _cb()
        ,->
          cb()
    ,(cb)->

      # 全件についてFaviconの決定を行う,見つからない場合は試しにリクエストしてみる
      async.forEach candidates,(cand,_cb)->

        if favicon.length > 0
          if favicon.match /[http|https]:\/\//
            cand.favicon = favicon
            _cb()
          else
            if favicon.charAt(0) is '/'
              cand.favicon = "#{urlObject.protocol}//#{urlObject.host}#{favicon}"
              _cb()
            else
              cand.favicon = "#{urlObject.protocol}//#{urlObject.host}/#{favicon}"
              _cb()

        else
          guess = "#{urlObject.protocol}//#{urlObject.host}/favicon.ico"
          request guess, (err,res,body)->
            cand.favicon = guess if res.statusCode is 200
            _cb()
      ,->
        cb()
    ],->

      if candidates.length is 0
        callback new Error('NotFoundRSSFeedError'),null
      else
        callback null,candidates

requestAndEncodeWithDetectCharset = (url,callback)->
  request.get
    uri: url
    encoding: null
  , (err,res,body)->
    return callback err,null if err

    charset = jschardet.detect(body).encoding

    if charset isnt ('utf-8' or 'UTF-8')
      converter = new iconv.Iconv(charset,'utf-8')
      body = converter.convert(body).toString()

    callback null,body

