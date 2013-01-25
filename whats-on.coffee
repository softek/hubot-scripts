# Description:
#   Interfaces with Dusty's audioscrobbler feed to see what's playing on the
#   spotify channel.
#
# Commands:
#   hubot what's (on|playing) - Responds with the most recent scrobbled track

http = require "http"
url = require "url"

module.exports = (robot) ->
  robot.respond /what'?s? (on|playing|song (is|was) (this|that)|are we listening to)\??/i, (msg) ->
    http.get(url.parse("http://ws.audioscrobbler.com/1.0/user/dustyburwell/recenttracks.rss"), (res) ->
      data = ""
      res.on("data", (chunk) -> data += chunk.toString())
      res.on("end", () ->
        matches = data.match(/<item>\n\W+<title>([^<]+)<\/title>/i)
        song = matches[1]

        msg.send decodeURIComponent(song)
      )
      res.on("error", () ->
        msg.send "I'm not sure..."
      )
    ).on("error", () ->
      msg.send "I'm not sure..."
    )
