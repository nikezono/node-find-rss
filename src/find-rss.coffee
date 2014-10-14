# dependency
jschardet  = require("jschardet")
iconv      = require 'iconv'
request    = require 'request'
async      = require 'async'

# utility
url        = require 'url'

parser = require "./parser"

module.exports = finder = (req,callback)->

  # Options
  finder.favicon = true unless finder.favicon?
  finder.getDetail = false unless finder.getDetail?

  return callback new Error("Not HTTP URL is provided."),null unless /^https?/.test req

  # urlプロパティの決定
  urlObject = url.parse req
  body = ""
  candidates = []
  async.series [(cb)->

    # HTML/XMLの取得
    requestAndEncodeWithDetectCharset req,(err,html)->
      return callback err,null if err
      body = html
      cb()

  ,(cb)->

    # HTML/XMLのParsing
    parser body,(err,cands)->
      return callback err,null if err
      candidates = cands
      cb()

  ,(cb)->

    for cand in candidates

      if /^https?/.test cand.href
        cand.url = cand.href
      else
        cand.url = "#{urlObject.protocol}//#{urlObject.host}#{cand.href}"
    cb()

  ,(cb)->

    # 詳細な情報の取得
    return cb() unless finder.getDetail
    newCandidates = []
    async.forEach candidates,(cand,_cb)->
      requestAndEncodeWithDetectCharset cand.url,(err,body)->
        return _cb() if err

        parser body,(error,cands)->
          return _cb() if err

          # 取得しておいたパラメタをを代入
          cands[0].favicon = cand.favicon
          cands[0].sitename = cand.sitename
          newCandidates.push cands[0]
          return _cb()
    ,->
      candidates = newCandidates
      cb()

  ,(cb)->

    # faviconの決定
    return cb() unless finder.favicon
    async.forEach candidates,(cand,_cb)->

      # 取得出来ている場合
      if cand.favicon?.length > 0

        # フルパスなら良し
        if /^https?/.test cand.favicon
          _cb()

        # hrefのみの場合は、urlを作る
        else
          if cand.favicon.charAt(0) is '/'
            cand.favicon = "#{urlObject.protocol}//#{urlObject.host}#{cand.favicon}"
            _cb()
          else
            cand.favicon = "#{urlObject.protocol}//#{urlObject.host}/#{cand.favicon}"
            _cb()

      # 取得できていない場合、/favicon.ico にアクセスしてみる
      else
        guess = "#{urlObject.protocol}//#{urlObject.host}/favicon.ico"
        request guess, (err,res,body)->
          cand.favicon = guess if res.statusCode is 200
          _cb()
    ,->
      cb()
  ],->

    if candidates.length is 0
      return callback new Error('NotFoundRSSFeedError'),null
    else
      return callback null,candidates

finder.setOptions = (opts)->
  finder.getDetail = opts.getDetail if opts.getDetail?
  finder.favicon  = opts.favicon if opts.favicon?

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

