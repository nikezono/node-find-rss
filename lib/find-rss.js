(function() {
  module.exports = function(req, callback) {
    var async, candidates, favicon, htmlparser, iconv, jschardet, parser, request, sitename, sitenameFlag, url;
    htmlparser = require("htmlparser2");
    jschardet = require("jschardet");
    iconv = require('iconv');
    async = require('async');
    url = require('url');
    request = require('request');
    candidates = [];
    sitename = '';
    sitenameFlag = false;
    favicon = '';
    parser = new htmlparser.Parser({
      onopentag: function(name, attr) {
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
        if (sitenameFlag) {
          return sitename = text;
        }
      },
      onclosetag: function(name) {
        if (name === "title") {
          return sitenameFlag = false;
        }
      }
    });
    return request.get({
      uri: req,
      encoding: null
    }, function(err, res, body) {
      var charset, converter, obj;
      if (err != null) {
        callback(err, null);
        return;
      }
      obj = url.parse(req);
      charset = jschardet.detect(body).encoding;
      if (charset !== ('utf-8' || 'UTF-8')) {
        converter = new iconv.Iconv(charset, 'utf-8');
        body = converter.convert(body).toString();
      }
      parser.write(body);
      parser.end();
      return async.forEach(candidates, function(cand, cb) {
        var guess;
        cand.sitename = sitename;
        if (cand.href.match(/[http|https]:\/\//)) {
          cand.url = cand.href;
        } else {
          cand.url = "" + obj.protocol + "//" + obj.host + cand.href;
        }
        if (favicon.length > 0) {
          if (favicon.match(/[http|https]:\/\//)) {
            cand.favicon = favicon;
            return cb();
          } else {
            if (favicon.charAt(0) === '/') {
              cand.favicon = "" + obj.protocol + "//" + obj.host + favicon;
              return cb();
            } else {
              cand.favicon = "" + obj.protocol + "//" + obj.host + "/" + favicon;
              return cb();
            }
          }
        } else {
          guess = "" + obj.protocol + "//" + obj.host + "/favicon.ico";
          return request(guess, function(err, res, body) {
            if (res.statusCode === 200) {
              cand.favicon = guess;
            }
            return cb();
          });
        }
      }, function() {
        if (candidates.length === 0) {
          return callback(new Error('NotFoundRSSFeedError'), null);
        } else {
          return callback(null, candidates);
        }
      });
    });
  };

}).call(this);
