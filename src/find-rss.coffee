module.exports = (req,callback)->

  # dependency
  htmlparser = require("htmlparser2")
  jschardet  = require("jschardet")
  iconv      = require 'iconv'

  # utility
  async        = require 'async'
  url          = require 'url'
  request      = require 'request'

  # instance property
  candidates   = []
  sitename     = ''
  sitenameFlag = false
  favicon      = ''
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
      sitename = text if sitenameFlag

    onclosetag: (name)->
      sitenameFlag = false if name is "title"
  )

  # main
  request.get
    uri: req
    encoding: null
  , (err,res,body)->
    if err?
      callback err,null
      return
    obj = url.parse req
    charset = jschardet.detect(body).encoding

    if charset isnt ('utf-8' or 'UTF-8')
      converter = new iconv.Iconv(charset,'utf-8')
      body = converter.convert(body).toString()

    # HTMLParser
    parser.write body
    parser.end()

    # リクエストされたURLが既にRSSフィードと思われる場合
    if argumentIsCandidate
      candidates = [
        title:req
        sitename:req
        url:req
        href:req
      ]

    async.forEach candidates,(cand,cb)->
      # sitename
      cand.sitename ||= sitename

      # url(href)
      if cand.href.match /[http|https]:\/\//
        cand.url = cand.href
      else
        cand.url = "#{obj.protocol}//#{obj.host}#{cand.href}"

      # favicon
      if favicon.length > 0
        if favicon.match /[http|https]:\/\//
          cand.favicon = favicon
          cb()
        else
          if favicon.charAt(0) is '/'
            cand.favicon = "#{obj.protocol}//#{obj.host}#{favicon}"
            cb()
          else
            cand.favicon = "#{obj.protocol}//#{obj.host}/#{favicon}"
            cb()

      else
        guess = "#{obj.protocol}//#{obj.host}/favicon.ico"
        request guess, (err,res,body)->
          cand.favicon = guess if res.statusCode is 200
          cb()
    ,->
      if candidates.length is 0
        callback new Error('NotFoundRSSFeedError'),null
      else
        callback null,candidates
