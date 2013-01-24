# Description:
#   Posts status updates when jenkins builds finish
# 
# Configuration: 
#   HUBOT_JENKINS_ROOM - The room to announce builds in

room = process.env.HUBOT_JENKINS_ROOM

module.exports = (robot) ->
  robot.router.post '/hubot/jenkins', (req, res) ->

    post = ''
    for k,v of req.body
      post = k

    json = JSON.parse post

    job = json.name
    phase = json.build.phase
    status = json.build.status
    url = json.build.full_url.replace /\s/g, '%20'

    if phase == "FINISHED"
      robot.messageRoom room, "Jenkins #{job} #{status}: #{url}"

    res.writeHead 200, 'OK'
    res.end()
