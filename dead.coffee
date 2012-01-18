# Generates a suggestion for where to go to lunch.
#
# These commands are grabbed from comment blocks at the top of each file.
#
# help - Displays all of the help commands that Hubot knows about.
# help <query> - Displays all help commands that match <query>.

module.exports = (robot) ->
  robot.respond /are you (dead|alive)\??\s*(.*)?$/i, (msg) ->
    msg.send 'Johnny five is alive'

  robot.respond /open the pod bay doors/i, (msg) ->
    msg.send "I can't do that, #{msg.message.user.name}"

