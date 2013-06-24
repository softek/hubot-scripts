http = require 'http'
TextMessage = require('hubot').TextMessage

# Description: 
#   Tell the robot what to say or hear on a schedule as if in a dream.
# 
# Commands:
#   robot tell me your dreams- List of dreams
#   robot forget dream (key)- Remove the dream #n
#   robot dream [key] at (timeofday) on (dayPattern) hear (message) - hear an imaginary command at (timeOfDay) every (dayPattern)
#   robot dream [key] at (timeofday) on (dayPattern) hear (message) - hear an imaginary command at (timeOfDay) every (dayPattern)
#   robot dream [key] at (timeofday) hear|speak (message) - on dayPattern is optional
#   robot dream (key) now - Ignore the schedule and have the specified dream right now

# http://en.wikipedia.org/wiki/You_talkin'_to_me%3F
youTalkinToMe = (msg, robot) ->
  input = msg.message.text.toLowerCase()
  name = robot.name.toLowerCase()
  input.indexOf(name) != -1

module.exports = (robot) ->

  dreams = robot.brain.data['dreams'] ? {}
  timeoutCookies = {}

  addDreamTimeout = (key) ->
    millisecondsPerDay = 24 * 60 * 60 * 1000
    dream = dreams[key]
    hour = parseInt(dream.time.match /^\d+/ )
    minute = parseInt(dream.time.match /\d+$/)
    now = new Date()
    timeoutToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, 0, 0).getTime()
    timeoutAt = if(timeoutToday <= now) then timeoutToday + millisecondsPerDay else timeoutToday
    timeUntilMs = timeoutAt - now.getTime()
    if(timeUntilMs > 0)
      timeoutCookies[key] = setTimeout (-> dreamAndReschedule(key)), timeUntilMs

  removeDreamTimeout = (key) ->
    clearTimeout timeoutCookies[key]
    delete timeoutCookies[key]

  dreamAndReschedule = (key) ->
    removeDreamTimeout key
    addDreamTimeout key
    doDream(dreams[key]) if new Date().toString().match(new RegExp(dreams[key].dayPattern,'i'))

  doDream = (dream) ->
    if(dream.command == "Imagine")
      dreamReceive dream
    else if(dream.command == "Speak")
      dreamSpeak dream

  dreamSpeak = (dream) ->
    robot.messageRoom dream.room, dream.message

  dreamReceive = (dream) ->
    robot.receive new TextMessage dream.user, dream.message, Math.floor(Math.random() * 2000000000).toString()

  robot.hear /dreams/i, (msg) ->
    return unless youTalkinToMe msg, robot
    msg.send "while I sleep, these are my dreams:"
    msg.send describe dream for key,dream of dreams

  robot.hear /forget dream (\S+)/i, (msg) ->
    return unless youTalkinToMe msg, robot
    key = msg.match[1]
    dream = dreams[key]
    if(dream)
      delete dreams[key]
      msg.send "I feel my dream slipping away: " + describe(dream)
      removeDreamTimeout key
    else "I don't remember a dream about #{key}."

  robot.hear /dream (\S+) now/i, (msg) ->
    return unless youTalkinToMe msg, robot
    key = msg.match[1]
    dream = dreams[key]
    doDream(dream)

  robot.hear /dream ?(\S+)? at (\d?\d:\d\d) (?:on ("[^"]+"|\S+) )?(hear|imagine|say|speak) +(.+)/i, (msg) ->
    return unless youTalkinToMe msg, robot
    getStandardCommand = (command) ->
      if((/say|speak/i).test(command))
        "Speak"
      else
        "Imagine"
    key = msg.match[1] ? "#" + Math.floor(Math.random() * 2000000000)
    dream =
      key: key
      time: msg.match[2]
      dayPattern: msg.match[3] ? "."
      command: getStandardCommand(msg.match[4])
      message: msg.match[5]
      user: msg.message.user
      room: msg.message.room
    dreams[key] = dream
    msg.send describe dream
    msg.finish()
    addDreamTimeout key

  describe = (dream) ->
    "My dream of #{dream.key}: Every day at #{dream.time}, I will see if it is #{dream.dayPattern}.  On #{dream.date} at #{dream.time}, #{dream.user.name} wants to #{dream.command} '#{dream.message}'."

  getDreams = ->
    robot.brain.get('dreams')

  setDreams = (dreams)->
    robot.brain.set('dreams', dreams)
