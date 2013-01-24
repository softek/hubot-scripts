# Description:
#   Generates a suggestion for where to go to lunch.
# 
# Commands: 
#   hubot what's for lunch? - Tells you what's for lunch.

module.exports = (robot) ->
  robot.respond /what'?s for lunch\??\s*(.*)?$/i, (msg) ->
    msg.send "Brobecks!"

