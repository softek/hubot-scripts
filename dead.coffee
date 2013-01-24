# Description:
#   Responds if the robot is(nt) dead
#
# Commands:
#   hubot are you (dead|alive)? - responds if hubot is alive
#   hubot open the pod bay doors - opens the pod bay doors, of course.

module.exports = (robot) ->
  robot.respond /are you (dead|alive)\??\s*(.*)?$/i, (msg) ->
    msg.send 'Johnny five is alive'

  robot.respond /open the pod bay doors/i, (msg) ->
    msg.send "I can't do that, #{msg.message.user.name}"

