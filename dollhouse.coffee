# Description:
#   Interacts with our actives (vms) through esxi
#
# Configuration:
#   HUBOT_CI_HOST - The hostname of the CI server (esxi)
#   HUBOT_CI_HOST_USERNAME - Username to use with authentication
#   HUBOT_CI_HOST_PASSWORD - The password to use
#   HUBOT_CI_ROOM - Room to announce to when reverting VMs
#
# Commands:
#   hubot list (actives|imprints) - displays the mappings between VM and MSI image
#   hubot unlock <vm> - Unlocks a VM by name
#   hubot lock <vm> <reason> - Locks a VM from being wiped via Hubot
#   hubot imprint <vm> with <image> - Maps a VM by name to MSI image location
#   hubot (stop|cancel) - Stop an impending revert operation
#   hubot wipe <vm> - Revert the given VM to the latest snapshot

spawn = require("child_process").spawn

ci = (robot) ->
   host = process.env.HUBOT_CI_HOST
   user = process.env.HUBOT_CI_HOST_USERNAME
   password = process.env.HUBOT_CI_HOST_PASSWORD
   room = process.env.HUBOT_CI_ROOM

   writeLog = (message) ->
      dateAndTime = (new Date()).toUTCString()
      console.log "#{dateAndTime}: #{message}"

   wipe = (active, callback) ->
      revert = spawn "/var/lib/gems/1.9.1/bin/vmware-revert", [host, user, password, "illum-qa-#{active.toLowerCase().trim()}"]
      stderr = ""
      stdout = ""

      revert.stderr.on "data", (data) ->
         stderr += data
      revert.stdout.on "data", (data) ->
         stdout += data

      revert.on "exit", (code) ->
         if code
            writeLog "Problem wiping #{active} on #{host}\n" + stdout + stderr

         callback code

   getImprint = (active) ->
      getImprints()[active.toLowerCase().trim()]

   setImprint = (active, imprint) ->
      getImprints()[active.toLowerCase().trim()] = imprint

   getImprints = () ->
      robot.brain.data.imprints ||= {}

   hasImprints = () ->
      Object.keys(getImprints()).length > 0

   getLocks = () ->
      robot.brain.data.imprint_locks ||= {}

   removeLock = (active) ->
      delete getLocks()[active.toLowerCase().trim()]

   getLock = (active) ->
      getLocks()[active.toLowerCase().trim()]

   setLock = (active, owner, reason) ->
      getLocks()[active.toLowerCase().trim()] =
         owner: owner
         reason: reason
         date: new Date().toString()

   robot.respond /list (actives|imprints)/i, (msg) ->
      if hasImprints()
         for active, imprint of getImprints()
            msg.send "#{active}: \"#{imprint}\""
      else
         msg.send "There are no actives."

   robot.respond /unlock (.*)/i, (msg) ->
      removeLock msg.match[1]

   robot.respond /lock ([^ ]*)(.*)/i, (msg) ->
      imrpint = msg.match[1]
      msg.send "Locking #{imprint}. \"unlock #{imprint}\" to clear this lock."
      reason = if msg.match.length is 3 then msg.match[2].trim() else "No reason given."
      setLock imprint, msg.message.user.name, msg.match[2]

   robot.respond /imprint (.*) with ([^ ]*)/i, (msg) ->
      active = msg.match[1]
      setImprint active, msg.match[2]

   robot.respond /(stop|cancel|wait)/i, (msg) ->
      if @wipeTimeout
         clearTimeout @wipeTimeout
         @wipeTimeout = null
         msg.send "Wipe stopped!"
      else
         msg.send "Sorry, I couldn't stop the wipe!"

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]

      unless active
         msg.send "Which Active did you mean?"
         return

      imprint = getImprint active
      lock = getLock active

      if lock
         msg.send "#{active} has been locked [#{lock.reason}] by #{lock.owner} on #{lock.date}"
      else if imprint
         msg.send "Wiping #{active} and imprinting #{imprint} in 10 seconds. Stop, cancel, or wait to prevent this from happening."
      else
         msg.send "Wiping #{active} in 10 seconds. Stop, cancel, or wait to prevent this from happening."

         @wipeTimeout = setTimeout(() =>
            if @wipeTimeout
               clearTimeout @wipeTimeout
               @wipeTimeout = null
               wipe active, (err) ->
                  if err
                     msg.send "I could not wipe #{active}."
                     writeLog err
                  else
                     robot.messageRoom room, "#{active} has been wiped!"
         , 10000)

   robot.router.get "/next-engagement/:active", (req, res) ->
      active = req.params.active
      imprint = getImprint active

      if imprint
         res.writeHead 200, "OK"
         res.write imprint
         writeLog "#{active} checked in."
      else
         res.writeHead 404, "Not Found"
         res.write "You are not scheduled for an engagement."
         writeLog "Hey! #{active} is looking for their next imprint but I didn't know what to do."

      res.end()

   robot.router.post "/engagement-complete", (req, res) ->
      reported = req.body or { active: 'Unknown', imprint: 'Unknown' }
      active = reported.active
      imprint = reported.imprint

      explanationFor =
         checkin: "#{active} had trouble checking in to get their imprint. They reported the following: \"#{reported.error}\""
         download: "#{active} had trouble downloading their imprint. The active said, \"#{reported.error}\""
         imprint: "#{active}'s imprint failed to install. It exited with error: \"#{reported.error}\""

      explainActivesProblem = () ->
         robot.messageRoom room, explanationFor[reported.state] or "Unknown error from #{active}."

      reportActivesSuccess = () ->
         robot.messageRoom room, "#{active}: \"Did I fall asleep?\". Hubot: Yes, just while #{imprint} was installing."

      if reported.status is "success" then reportActivesSuccess()
      else explainActivesProblem()

      res.writeHead 200, "OK"
      res.end()

module.exports = ci
