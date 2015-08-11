(function() {
  var async, finder, iconv, jschardet, parser, request, requestAndEncodeWithDetectCharset, url;

  jschardet = require("jschardet");

  iconv = require('iconv-lite');

  request = require('request');

  async = require('async');

  url = require('url');

  parser = require("./parser");

  module.exports = finder = function(req, callback) {
    var body, candidates, urlObject;
    if (typeof req === "string") {
      req = {
        url: req
      };
    }
    req.encoding = null;
    if (finder.favicon == null) {
      finder.favicon = true;
    }
    if (finder.getDetail == null) {
      finder.getDetail = false;
    }
    if (!/^https?/.test(req.url)) {
      return callback(new Error("Not HTTP URL is provided."), null);
    }
    urlObject = url.parse(req.url);
    body = "";
    candidates = [];
    return async.series([
      function(cb) {
        return requestAndEncodeWithDetectCharset(req, function(err, html) {
          if (err) {
            return cb(err);
          }
          body = html;
          return cb();
        });
      }, function(cb) {
        return parser(body, function(err, cands) {
          if (err) {
            return cb(err);
          }
          candidates = cands;
          return cb();
        });
      }, function(cb) {
        var cand, i, len;
        for (i = 0, len = candidates.length; i < len; i++) {
          cand = candidates[i];
          if (cand.link != null) {
            cand.url = req.url;
            cand.sitename = cand.title;
          } else {
            if (/^https?/.test(cand.href)) {
              cand.url = cand.href;
            } else {
              cand.url = urlObject.protocol + "//" + urlObject.host + cand.href;
            }
          }
        }
        return cb();
      }, function(cb) {
        var newCandidates;
        if (!finder.getDetail) {
          return cb();
        }
        if (candidates.length > 0 && (candidates[0].link != null)) {
          return cb();
        }
        newCandidates = [];
        return async.forEach(candidates, function(cand, _cb) {
          req.url = cand.url;
          return requestAndEncodeWithDetectCharset(req, function(err, body) {
            if (err) {
              return _cb();
            }
            return parser(body, function(error, cands) {
              if (error) {
                return _cb();
              }
              if (cands.length === 0) {
                return _cb();
              }
              cands[0].favicon = cand.favicon;
              cands[0].sitename = cand.sitename;
              cands[0].url = cand.url;
              newCandidates.push(cands[0]);
              return _cb();
            });
          });
        }, function() {
          candidates = newCandidates;
          return cb();
        });
      }, function(cb) {
        if (!finder.favicon) {
          return cb();
        }
        return async.each(candidates, function(cand, _cb) {
          var guess, ref;
          if (((ref = cand.favicon) != null ? ref.length : void 0) > 0) {
            if (/^https?/.test(cand.favicon)) {
              return _cb();
            } else {
              if (cand.favicon.charAt(0) === '/') {
                cand.favicon = urlObject.protocol + "//" + urlObject.host + cand.favicon;
                return _cb();
              } else {
                cand.favicon = urlObject.protocol + "//" + urlObject.host + "/" + cand.favicon;
                return _cb();
              }
            }
          } else {
            guess = urlObject.protocol + "//" + urlObject.host + "/favicon.ico";
            return request(guess, function(err, res, body) {
              if (err || (res != null ? res.statusCode : void 0) !== 200) {
                return _cb;
              }
              cand.favicon = guess;
              return _cb();
            });
          }
        }, function() {
          return cb();
        });
      }
    ], function(err) {
      if (err) {
        return callback(err, null);
      } else {
        return callback(null, candidates);
      }
    });
  };

  finder.setOptions = function(opts) {
    if (opts.getDetail != null) {
      finder.getDetail = opts.getDetail;
    }
    if (opts.favicon != null) {
      return finder.favicon = opts.favicon;
    }
  };

  requestAndEncodeWithDetectCharset = function(req, callback) {
    return request.get(req, function(err, res, body) {
      var charset;
      if (err) {
        return callback(err, null);
      }
      charset = jschardet.detect(body).encoding;
      if (!charset || charset === "" || charset === null) {
        return callback(new Error('NotFoundEncodingError'), null);
      }
      if (charset !== ('utf-8' || 'UTF-8')) {
        body = iconv.decode(body, charset);
      }
      return callback(null, body);
    });
  };

}).call(this);
