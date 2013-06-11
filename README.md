node-find-rss
---

find rss feeds in url

wrapper of [htmlparser2](https://github.com/fb55/htmlparser2)

##install

* using npm:

    npm install find-rss

* or using package.json

    "find-rss": "*"

##usage
    # Coffeescript
    finder = require 'find-rss'
    finder "http://www.apple.com/",(candidates)->
      console.log candidates

      # =>
      # [ { rel: 'alternate',
            type: 'application/rss+xml',
            title: 'RSS',
            href: 'http://images.apple.com/main/rss/hotnews/hotnews.rss',
            url: 'http://images.apple.com/main/rss/hotnews/hotnews.rss' } ]
