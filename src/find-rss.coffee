module.exports = (req,callback)->
  # dependency
  htmlparser = require("htmlparser2")
  csDetector = require("node-icu-charset-detector")
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

  parser = new htmlparser.Parser(
    onopentag: (name, attr) ->
      candidates.push attr if name is "link" and attr.type is "application/rss+xml" or attr.type is "application/atom+xml"
      favicon = attr.href if name is 'link' and (attr.rel is 'icon' or attr.rel is 'shortcut icon' or attr.type is 'image/x-icon')
      sitenameFlag = true if name is "title"

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
    charset = csDetector.detectCharset(body).toString()

    if charset isnt ('utf-8' or 'UTF-8')
      converter = new iconv.Iconv(charset,'utf-8')
      body = converter.convert(body).toString()

    parser.write body
    parser.end()

    async.forEach candidates,(cand,cb)->
      # sitename
      cand.sitename = sitename

      # url(href)
      if cand.href.match /[http|https]:\/\//
        cand.url = cand.href
      else
        cand.url = "#{obj.protocol}//#{obj.host}#{cand.href}"

      # favicon
      if favicon.length > 0
        if favicon.match /[http|https]:\/\//
          cand.favicon = favicon
        else
          console.log favicon
          if favicon.charAt(0) is '/'
            cand.favicon = "#{obj.protocol}//#{obj.host}#{favicon}"
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
        callback 'no such rss feeds.',null 
      else
        callback null,candidates
