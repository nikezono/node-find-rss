(function() {
  var async, htmlparser, iconv, jschardet, request, requestAndEncodeWithDetectCharset, url;

  htmlparser = require("htmlparser2");

  jschardet = require("jschardet");

  iconv = require('iconv');

  async = require('async');

  url = require('url');

  request = require('request');

  module.exports = function(req, callback) {
    var argumentIsCandidate, candidates, favicon, feedTitle, parser, sitename, sitenameFlag, urlObject;
    candidates = [];
    sitename = '';
    sitenameFlag = false;
    favicon = '';
    feedTitle = '';
    argumentIsCandidate = false;
    parser = new htmlparser.Parser({
      onopentag: function(name, attr) {
        if (["feed", "rss", "atom"].indexOf(name) > -1) {
          argumentIsCandidate = true;
        }
        if (name === "link" && (['application/rss+xml', 'application/atom+xml', 'application/rdf+xml', 'application/rss', 'application/atom', 'application/rdf', 'text/rss+xml', 'text/atom+xml', 'text/rdf+xml', 'text/rss', 'text/atom', 'text/rdf'].indexOf(attr.type) >= 0)) {
          candidates.push(attr);
        }
        if (name === 'link' && (attr.rel === 'icon' || attr.rel === 'shortcut icon' || attr.type === 'image/x-icon')) {
          favicon = attr.href;
        }
        if (name === "title") {
          return sitenameFlag = true;
        }
      },
      ontext: function(text) {
        if (sitename === '' && argumentIsCandidate) {
          feedTitle = text;
        }
        if (sitenameFlag) {
          return sitename = text;
        }
      },
      onclosetag: function(name) {
        if (name === "title") {
          return sitenameFlag = false;
        }
      }
    }, {
      recognizeCDATA: true
    });
    urlObject = url.parse(req);
    return requestAndEncodeWithDetectCharset(req, function(err, body) {
      if (err) {
        return callback(err, null);
      }
      parser.write(body);
      parser.end();
      return async.series([
        function(cb) {
          if (argumentIsCandidate) {
            candidates = [
              {
                title: feedTitle,
                sitename: req,
                url: req,
                href: req
              }
            ];
            return cb();
          } else {
            return async.forEach(candidates, function(cand, _cb) {
              cand.sitename = sitename;
              if (cand.href.match(/[http|https]:\/\//)) {
                cand.url = cand.href;
              } else {
                cand.url = "" + urlObject.protocol + "//" + urlObject.host + cand.href;
              }
              return requestAndEncodeWithDetectCharset(cand.url, function(err, body) {
                var innerFeedTitle, innerParser, isFeed, titleFlag;
                if (err) {
                  return _cb();
                }
                innerFeedTitle = '';
                isFeed = false;
                titleFlag = false;
                innerParser = new htmlparser.Parser({
                  onopentag: function(name, attr) {
                    if (["feed", "rss", "atom"].indexOf(name) > -1) {
                      isFeed = true;
                    }
                    if (name === "title") {
                      return titleFlag = true;
                    }
                  },
                  ontext: function(text) {
                    if (titleFlag && isFeed) {
                      return innerFeedTitle || (innerFeedTitle = text);
                    }
                  },
                  onclosetag: function(name) {
                    if (name === "title") {
                      return titleFlag = false;
                    }
                  }
                }, {
                  recognizeCDATA: true
                });
                innerParser.write(body);
                innerParser.end();
                cand.title = unescape(innerFeedTitle);
                return _cb();
              });
            }, function() {
              return cb();
            });
          }
        }, function(cb) {
          return async.forEach(candidates, function(cand, _cb) {
            var guess;
            if (favicon.length > 0) {
              if (favicon.match(/[http|https]:\/\//)) {
                cand.favicon = favicon;
                return _cb();
              } else {
                if (favicon.charAt(0) === '/') {
                  cand.favicon = "" + urlObject.protocol + "//" + urlObject.host + favicon;
                  return _cb();
                } else {
                  cand.favicon = "" + urlObject.protocol + "//" + urlObject.host + "/" + favicon;
                  return _cb();
                }
              }
            } else {
              guess = "" + urlObject.protocol + "//" + urlObject.host + "/favicon.ico";
              return request(guess, function(err, res, body) {
                if (res.statusCode === 200) {
                  cand.favicon = guess;
                }
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
    });
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
      if (charset !== ('utf-8' || 'UTF-8')) {
        converter = new iconv.Iconv(charset, 'utf-8');
        body = converter.convert(body).toString();
      }
      return callback(null, body);
    });
  };

}).call(this);
