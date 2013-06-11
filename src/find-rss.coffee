module.exports = (req,callback)->
  # dependency
  htmlparser = require("htmlparser2")
  parser = new htmlparser.Parser(
    onopentag: (name, attr) ->
      candidates.push attr if name is "link" and attr.type is "application/rss+xml"
  )

  # utility
  async      = require 'async'
  url        = require 'url'
  path       = require 'path'
  http       = require 'http'

  # instance property
  candidates = []

  # main
  obj = url.parse req
  http.get
    host:obj.host
    port:obj.port, (res)->
      body = ""
      res.on 'data',(chunk)->
        body += chunk
      res.on 'end',->
        parser.write body
        parser.end()
        async.forEach candidates,(cand,cb)->
          if cand.href.match /[http|https]:\/\//
            cand.url = cand.href
          else
            cand.url = "#{obj.protocol}//#{obj.host}#{cand.href}"
          cb()
        ,->
          callback candidates