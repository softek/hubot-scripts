http = require 'http'

# Description: 
#   Listens for patterns matching youtrack issues and provides information about 
#   them
# 
# Commands:
#   #project-number - responds with a summary of the issue

host = 'youtrack'
login = process.env.HUBOT_YOUTRACK_USERNAME
password = process.env.HUBOT_YOUTRACK_PASSWORD

module.exports = (robot) ->
  robot.hear /#([^-]+-[\d]+)/i, (msg) ->
    issueId = msg.match[1]

    options = {
      host: host
      path: "/rest/user/login?login=#{login}&password=#{password}",
      method: "POST"
    }

    login_req = http.request options, (login_res) ->
      cookies = (cookie.split(';')[0] for cookie in login_res.headers['set-cookie'])
      issue_options = {
        host: host,
        path: "/rest/issue/#{issueId}",
        headers: {
          Cookie: cookies,
          Accept: 'application/json'
        }
      }

      issue_req = http.get issue_options, (issue_res) ->
        data = ''

        issue_res.on 'data', (chunk) ->
          data += chunk

        issue_res.on 'end', () ->
          issue = JSON.parse data
          
          if issue.field
            summary = field.value for field in issue.field when field.name == 'summary'
            msg.send "You're talking about http://#{host}/issue/#{issueId}\r\nsummary: #{summary}"
          else
            msg.send "I'd love to tell you about it, but I couldn't find that issue"

        issue_res.on 'error', () ->
          msg.send "I'd love to tell you about it, but there was an error looking up that issue"

      issue_req.on 'error', (e) ->
        msg.send "I'd love to tell you about it, but there was an error looking up that issue"

    login_req.end()
