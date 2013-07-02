module.exports = (req,callback)->
  # dependency
  htmlparser = require("htmlparser2")
  parser = new htmlparser.Parser(
    onopentag: (name, attr) ->
      candidates.push attr if name is "link" and attr.type is "application/rss+xml" or attr.type is "application/atom+xml"
  )

  # utility
  async      = require 'async'
  url        = require 'url'
  request    = require 'request'

  # instance property
  candidates = []

  # main
  request req, (err,res,body)->
    if err?
      callback err,null 
      return
    obj = url.parse req
    parser.write body
    parser.end()
    async.forEach candidates,(cand,cb)->
      if cand.href.match /[http|https]:\/\//
        cand.url = cand.href
      else
        cand.url = "#{obj.protocol}//#{obj.host}#{cand.href}"
      cb()
    ,->
      if candidates.length is 0
        callback 'no such rss feeds.',null 
      else
        callback null,candidates
