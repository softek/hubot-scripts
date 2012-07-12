
room = process.env.HUBOT_JENKINS_ROOM

module.exports = (robot) ->
  robot.router.post '/hubot/jenkins', (req, res) ->
    job = req.body.name
    phase = req.body.build.phase
    status = req.body.build.status
    url = req.body.build.fullUrl

    robot.messageRoom room, "Jenkins #{job} #{phase}: #{url}"

    res.writeHead 200, 'OK'
    res.end()