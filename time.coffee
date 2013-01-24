# Description: 
#   Tells information about the time of day
# 
# Commands:
#   hubot tell time - responds with what time block we're in

module.exports = (robot) ->
  robot.respond /tell time/i, (msg) ->
    date = new Date()
    hour = date.getHours()

    if (hour >= 8 and hour < 11)
      msg.send 'It\'s morning time. McMuffin anyone?'
    else if (hour >= 11 and hour < 13)
      msg.send 'It\'s lunch time!!'
    else if (hour >= 13 and hour < 17)
      msg.send 'It\'s afternoon. Let\'s go to QT!'
    else
      msg.send 'It\'s five o\'clock somewhere. Go home fools!'
