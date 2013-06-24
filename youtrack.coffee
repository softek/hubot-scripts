http = require 'http'

# Description: 
#   Listens for patterns matching youtrack issues and provides information about 
#   them
# 
# Commands:
#   #project-number - responds with a summary of the issue
#   robot what are my issues - lists issues assigned to me
#   robot what should we do - lists issues for the team
#   robot triage (state) - lists issues of the specified state, like Unreviewed

host = 'youtrack'
username = process.env.HUBOT_YOUTRACK_USERNAME
password = process.env.HUBOT_YOUTRACK_PASSWORD
defaultTriageState = process.env.HUBOT_YOUTRACK_TRIAGE_STATE ? "Unreviewed"

# http://en.wikipedia.org/wiki/You_talkin'_to_me%3F
youTalkinToMe = (msg, robot) ->
  input = msg.message.text.toLowerCase()
  name = robot.name.toLowerCase()
  input.indexOf(name) != -1

getProject = (msg) ->
  s = msg.message.room.replace /-.*/, ''
  if s == 'Shell'
    process.env.HUBOT_YOUTRACK_DEFAULT_PROJECT
  else
    s

module.exports = (robot) ->

  robot.hear /what (are )?my issues/i, (msg) ->
    msg.send "@#{msg.message.user.name}, you have many issues.  Shall I enumerate them?  I think not."   if Math.random() < .2

  robot.hear /what ((are )?my issues|am I (doing|working on|assigned))/i, (msg) ->
    return unless youTalkinToMe msg, robot
    filter = "for:+#{getUserNameFromMessage(msg)}+state:-Resolved,%20-Completed,%20-Blocked%20,%20-{To%20be%20discussed}"
    askYoutrack "/rest/issue?filter=#{filter}&with=summary&with=state", (err, issues) -> 
      handleIssues err, issues, msg, filter

  robot.hear /what (can|might|should)\s+(I|we)\s+(do|work on)/i, (msg) ->
    return unless youTalkinToMe msg, robot
    filter = "Project%3a%20#{getProject(msg)}%20state:-Resolved,%20-Completed,%20-Blocked%20,%20-{To%20be%20discussed}"
    askYoutrack "/rest/issue?filter=#{filter}&with=summary&with=state&max=100", (err, issues) -> 
      handleIssues err, issues, msg, filter

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

  handleIssues = (err, issues, msg, filter) ->
    msg.send if err?
        'Not to whine, but\r\n' + err.toString()
      else if not issues.issue.length
        "#{msg.message.user.name}, I guess you get to go home because there's nothing to do"
      else
        topIssues = if issues.issue.length <= 5 then issues.issue else issues.issue.slice 0, 5
        resp = "#{msg.message.user.name}, perhaps you will find one of these #{topIssues} #{getProject(msg)} issues to your liking:\r\n"
        issueLines = for issue in topIssues
          summary = issue.field[0].value
          state = issue.field[1].value
          issueId = issue.id
          verb = (if state.toString() == "Open" then "Start" else "Finish")
          "#{verb} \"#{summary}\" (http://#{host}/issue/#{issueId})"
        resp += issueLines.join ',\r\nor maybe '
        if topIssues.length != issues.issue.length
          url = "http://#{host}/issues/?q=#{filter}"
          resp+= '\r\n' + "or maybe these #{issues.issue.length}: #{url}"
        resp

  getUserNameFromMessage = (msg) ->
    user = msg.message.user.name
    user = 'me' if user = "Shell"
    user

  triageState = /triage(?: ("[^"]+"|[^ ]+))?/i
  robot.hear triageState, (msg) ->
    return unless youTalkinToMe msg, robot
    state = (msg.match[1] ? defaultTriageState).replace /"/g, ''
    project = getProject(msg)
    triage project, state, msg.room

  triage = (project, state, room)->
    filter = "Project%3a%20#{project}%20state:#{state}"
    askYoutrack "/rest/issue?filter=#{filter}&with=summary&with=state&max=100", (err, issues) -> 
      handleTriageIssues err, issues, room, filter

  handleTriageIssues = (err, issues, room, filter) ->
    filterDescription = filter.replace /(?:(?:[a-z0-9_]|%[0-9a-f]{2}))+?(?::|%3a)(?: |%20)?([^ %]+)/ig, "$1 "
    robot.messageRoom room, if err?
        'Not to whine, but\r\n' + err.toString()
      else if not issues.issue.length
        "Wow, we're fresh out of #{filterDescription} issues.  Leave this triage process to me.  #{robot.name} knows what to do."
      else
        topIssues = if issues.issue.length <= 5 then issues.issue else issues.issue.slice 0, 5
        resp = "I found these #{topIssues.length} #{filterDescription} issues:\r\n"
        issueLines = for issue in topIssues
          summary = issue.field[0].value
          state = issue.field[1].value
          issueId = issue.id
          verb = "Triage"
          "#{verb} \"#{summary}\" (http://#{host}/issue/#{issueId})"
        resp += issueLines.join ',\r\nor maybe '
        if topIssues.length != issues.issue.length
          url = "http://#{host}/issues/?q=#{filter}"
          resp += '\r\n' + "and these #{issues.issue.length}: #{url}"
        resp

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