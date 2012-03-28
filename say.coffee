# Echos whatever is sent to the endpoint into a room
module.exports = (robot) ->

  robot.router.post '/hubot/say', (req, res) ->
    robot.messageRoom req.body.room, req.body.msg
    res.writeHead 200, 'OK'
    res.end()
