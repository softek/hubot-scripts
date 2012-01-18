# Generates a suggestion for where to go to lunch.
#
# These commands are grabbed from comment blocks at the top of each file.
#
# help - Displays all of the help commands that Hubot knows about.
# help <query> - Displays all help commands that match <query>.

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
