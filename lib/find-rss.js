(function() {
  var async, finder, iconv, jschardet, parser, request, requestAndEncodeWithDetectCharset, url;

  jschardet = require("jschardet");

  iconv = require('iconv');

  request = require('request');

  async = require('async');

  url = require('url');

  parser = require("./parser");

  module.exports = finder = function(req, callback) {
    var body, candidates, urlObject;
    if (finder.favicon == null) {
      finder.favicon = true;
    }
    if (finder.getDetail == null) {
      finder.getDetail = false;
    }
    if (!/^https?/.test(req)) {
      return callback(new Error("Not HTTP URL is provided."), null);
    }
    urlObject = url.parse(req);
    body = "";
    candidates = [];
    return async.series([
      function(cb) {
        return requestAndEncodeWithDetectCharset(req, function(err, html) {
          if (err) {
            return callback(err, null);
          }
          body = html;
          return cb();
        });
      }, function(cb) {
        return parser(body, function(err, cands) {
          if (err) {
            return callback(err, null);
          }
          candidates = cands;
          return cb();
        });
      }, function(cb) {
        var cand, _i, _len;
        for (_i = 0, _len = candidates.length; _i < _len; _i++) {
          cand = candidates[_i];
          if (cand.link != null) {
            cand.url = req;
            cand.sitename = cand.title;
          } else {
            if (/^https?/.test(cand.href)) {
              cand.url = cand.href;
            } else {
              cand.url = "" + urlObject.protocol + "//" + urlObject.host + cand.href;
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
          return requestAndEncodeWithDetectCharset(cand.url, function(err, body) {
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
        return async.forEach(candidates, function(cand, _cb) {
          var guess, _ref;
          if (((_ref = cand.favicon) != null ? _ref.length : void 0) > 0) {
            if (/^https?/.test(cand.favicon)) {
              return _cb();
            } else {
              if (cand.favicon.charAt(0) === '/') {
                cand.favicon = "" + urlObject.protocol + "//" + urlObject.host + cand.favicon;
                return _cb();
              } else {
                cand.favicon = "" + urlObject.protocol + "//" + urlObject.host + "/" + cand.favicon;
                return _cb();
              }
            }
          } else {
            guess = "" + urlObject.protocol + "//" + urlObject.host + "/favicon.ico";
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
    ], function() {
      if (candidates.length === 0) {
        return callback(new Error('NotFoundRSSFeedError'), null);
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

  requestAndEncodeWithDetectCharset = function(url, callback) {
    return request.get({
      uri: url,
      encoding: null
    }, function(err, res, body) {
      var charset, converter;
      if (err) {
        return callback(err, null);
      }
      charset = jschardet.detect(body).encoding;
      if (!charset || charset === "" || charset === null) {
        return callback(new Error('NotFoundEncodingError'), null);
      }
      if (charset !== ('utf-8' || 'UTF-8')) {
        converter = new iconv.Iconv(charset, 'utf-8');
        body = converter.convert(body).toString();
      }
      return callback(null, body);
    });
  };

}).call(this);
