# dependency
jschardet  = require("jschardet")
iconv      = require 'iconv-lite'
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
      return cb err if err
      body = html
      cb()

  ,(cb)->

    # HTML/XMLのParsing
    parser body,(err,cands)->
      return cb err if err
      candidates = cands
      cb()

  ,(cb)->

    for cand in candidates
      if cand.link?

        cand.url = req
        cand.sitename = cand.title

      else

        if /^https?/.test cand.href
          cand.url = cand.href
        else
          cand.url = "#{urlObject.protocol}//#{urlObject.host}#{cand.href}"
    cb()

  ,(cb)->

    # 詳細な情報の取得
    return cb() unless finder.getDetail

    return cb() if candidates.length > 0 and candidates[0].link? # 既に詳細情報
    newCandidates = []
    async.forEach candidates,(cand,_cb)->
      requestAndEncodeWithDetectCharset cand.url,(err,body)->
        return _cb() if err

        parser body,(error,cands)->
          return _cb() if error
          return _cb() if cands.length is 0

          # 取得しておいたパラメタを代入
          cands[0].favicon = cand.favicon
          cands[0].sitename = cand.sitename
          cands[0].url = cand.url
          newCandidates.push cands[0]
          return _cb()
    ,->
      candidates = newCandidates
      cb()

  ,(cb)->

    # faviconの決定
    return cb() unless finder.favicon
    async.each candidates,(cand,_cb)->
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
          return _cb if err or res?.statusCode isnt 200
          cand.favicon = guess
          _cb()
    ,->
      cb()
  ],(err)->

    if err
      return callback err,null
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
    if not charset or charset is "" or charset is null
      return callback new Error('NotFoundEncodingError'),null

    if charset isnt ('utf-8' or 'UTF-8')
      body = iconv.decode(body, charset)

    return callback null,body
