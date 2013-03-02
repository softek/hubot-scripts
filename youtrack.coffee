http = require 'http'

# Description: 
#   Listens for patterns matching youtrack issues and provides information about 
#   them
# 
# Commands:
#   #project-number - responds with a summary of the issue

host = 'youtrack'
username = process.env.HUBOT_YOUTRACK_USERNAME
password = process.env.HUBOT_YOUTRACK_PASSWORD

module.exports = (robot) ->

  robot.hear /what (are )?my issues/i, (msg) ->
    msg.send "@#{msg.message.user.name}, you have many issues.  Shall I enumerate them?  I think not."   if Math.random() < .2

  robot.hear /what ((are )?my issues|am I (doing|working on|assigned))/i, (msg) ->
    filter = "for:+#{getUserNameFromMessage(msg)}+state:-Resolved,%20-Completed,%20-Blocked%20,%20-{To%20be%20discussed}"
    askYoutrack "/rest/issue?filter=#{filter}&with=summary&with=state", (err, issues) -> 
      handleIssues err, issues, msg

  robot.hear /what (can|might|should)\s+(I|we)\s+(do|work on)/i, (msg) ->
    filter = "state:-Resolved,%20-Completed,%20-Blocked%20,%20-{To%20be%20discussed}"
    askYoutrack "/rest/issue?filter=#{filter}&with=summary&with=state&max=25", (err, issues) -> 
      handleIssues err, issues, msg

  hashTagYoutrackIssueNumber = /#([^-]+-[\d]+)/i
  robot.hear hashTagYoutrackIssueNumber, (msg) ->
    issueId = msg.match[1]
    askYoutrack "/rest/issue/#{issueId}", (err, issue) ->
      return msg.send "I'd love to tell you about it, but there was an error looking up that issue" if err?
      if issue.field
        summary = field.value for field in issue.field when field.name == 'summary'
        msg.send "You're talking about http://#{host}/issue/#{issueId}\r\nsummary: #{summary}"
      else
        msg.send "I'd love to tell you about it, but I couldn't find that issue"

  handleIssues = (err, issues, msg) ->
    console.log 'unknown MSG-----------------------' unless msg?
    msg.send if err?
        'Not to whine, but\r\n' + err.toString()
      else if not issues.issue.length
        "#{msg.message.user.name}, I guess you get to go home because there's nothing to do"
      else
        resp = "#{msg.message.user.name}, perhaps you will find one of these #{issues.issue.length} issues to your liking:\r\n"
        issueLines = for issue in issues.issue
          summary = issue.field[0].value
          state = issue.field[1].value
          issueId = issue.id
          verb = (if state.toString() == "Open" then "Start" else "Finish")
          "#{verb} \"#{summary}\" #{state} (http://#{host}/issue/#{issueId})"
        resp += issueLines.join ',\r\nor maybe '

  getUserNameFromMessage = (msg) ->
    user = msg.message.user.name
    user = 'me' if user = "Shell"
    user

  askYoutrack = (path, callback) ->
    login (login_res) ->
      cookies = (cookie.split(';')[0] for cookie in login_res.headers['set-cookie'])
      ask_options = {
        host: host,
        path: path,
        headers: {
          Cookie: cookies,
          Accept: 'application/json'
        }
      }

      ask_req = http.get ask_options, (ask_res) ->
        data = ''

        ask_res.on 'data', (chunk) ->
          data += chunk

        ask_res.on 'end', () ->
          answer = JSON.parse data
          callback null, answer

        ask_res.on 'error', (err) ->
          callback err ? new Error 'Error getting answer from youtrack'

      ask_req.on 'error', (e) ->
        callback e ? new Error 'Error asking youtrack'

  login = (handler) ->
    options = {
      host: host
      path: "/rest/user/login?login=#{username}&password=#{password}",
      method: "POST"
    }

    login_req = http.request options, handler
    login_req.end()
