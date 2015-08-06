
/*
 *
 * parser.coffee
 * htmlBodyからRSSの候補を取得する
 * ついでにfaviconも取得する
 *
 */

(function() {
  var FeedParser, exports, htmlparser;

  FeedParser = require('feedparser');

  htmlparser = require('htmlparser2');

  module.exports = exports = function(htmlBody, callback) {
    var argumentIsCandidate, cand, candidates, favicon, feedparser, i, len, parser, sitename, sitenameFlag;
    candidates = [];
    sitename = "";
    favicon = "";
    argumentIsCandidate = false;
    sitenameFlag = false;
    parser = new htmlparser.Parser({
      onopentag: function(name, attr) {
        if (/(feed)|(atom)|(rdf)|(rss)/.test(name)) {
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
    parser.write(htmlBody);
    parser.end();
    if (argumentIsCandidate) {
      feedparser = new FeedParser();
      candidates = [];
      feedparser.on('error', function(error) {
        return callback(error, null);
      });
      feedparser.on('readable', function() {
        var data;
        if (candidates.length === 0) {
          data = this.meta;
          return candidates.push(data);
        }
      });
      feedparser.write(htmlBody);
      return feedparser.end(function() {
        return callback(null, candidates);
      });
    } else {
      for (i = 0, len = candidates.length; i < len; i++) {
        cand = candidates[i];
        cand.sitename = sitename;
        cand.favicon = favicon;
      }
      return callback(null, candidates);
    }
  };

}).call(this);
