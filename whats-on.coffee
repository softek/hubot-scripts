# Description:
#   Interfaces with Dusty's audioscrobbler feed to see what's playing on the
#   spotify channel.
#
# Commands:
#   hubot what's (on|playing) - Responds with the most recent scrobbled track

http = require "http"
url = require "url"

# Regex test cases:
#   what's playing?
#   what's playing
#   whats playing?
#   whats playing
#   what's playin?
#   what's playin
#   whats playin?
#   whats playin
#   what's on?
#   what's on
#   whats on?
#   whats on
#   what song was that?
#   what song was that
#   what song is this?
#   what song is this
#   what are we listening to?
#   what are we listening to
#   what song are we listening to?
#   what song are we listening to
#   music me
#   song me

module.exports = (robot) ->
  robot.respond /(what'?s? (on|playing?|song (is|was) (this|that)|(song )?are we listening to)\??|song me|music me)/i, (msg) ->
    http.get(url.parse("http://ws.audioscrobbler.com/1.0/user/illuminatesup/recenttracks.rss"), (res) ->
      data = ""
      res.on("data", (chunk) -> data += chunk.toString())
      res.on("end", () ->
        matches = data.match(/<item>\n\W+<title>([^<]+)<\/title>/i)
        song = matches[1]

        msg.send song.replace(/&amp;/ig, "&")
      )
      res.on("error", () ->
        msg.send "I'm not sure..."
      )
    ).on("error", () ->
      msg.send "I'm not sure..."
    )
