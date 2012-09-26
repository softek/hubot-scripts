spawn = require("child_process").spawn

ci = (robot) ->
   host = process.env.HUBOT_CI_HOST
   user = process.env.HUBOT_CI_HOST_USERNAME
   password = process.env.HUBOT_CI_HOST_PASSWORD

   writeLog = (message) ->
      dateAndTime = (new Date()).toUTCString()
      console.log "#{dateAndTime}: #{message}" 

   wipe = (active, callback) ->
      revert = spawn "vmware-revert", [host, user, password, "illum-qa-#{active.toLowerCase().trim()}"] 
      revert.on "exit", (code) ->
         callback if code is 0 then code else null 

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
         date: new Date()
   
   robot.respond /list (actives|imprints)/i, (msg) ->
      if hasImprints()
         for active, imprint of getImprints()
            msg.send "#{active}: \"#{imprint}\"" 
      else
         msg.send "There are no actives."
   
   robot.respond /release lock on (.*)/, (msg) ->
      removeLock msg.match[1]
      
   robot.respond /lock down ([^ ]*) (.*)/, (msg) ->
      setLock msg.match[1], msg.message.user.name, msg.match[2]

   robot.respond /imprint (.*) with ([^ ]*)/i, (msg) ->
      active = msg.match[1]
      setImprint active, msg.match[2]    

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]
      
      unless active
         msg.send "What Active did you mean?" 
         return
      
      imprint = getImprint active
      lock = getLock active

      if imprint and lock 
         msg.send "Sorry #{active} cannot be imprinted. \"#{lock.reason}\" by #{lock.owner} on #{lock.date}"
      else if imprint
         msg.send "Wiping #{active} and imprinting #{imprint}."
         wipe active, (err) ->
            writeLog "Oops! I had trouble starting the wipe for #{active}!" if err
      else
         msg.send "Sorry, #{active} is blank. Give #{active} an imprint with the command: imprint #{active} with <<IMPRINT>>"

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
         writeLog explanationFor[reported.state] or "Unknown error from #{active}."
      
      reportActivesSuccess = () ->
         writeLog "#{active}: \"Did I fall asleep?\". Hubot: Yes, just while #{imprint} was installing."
      
      if reported.status is "success" then reportActivesSuccess()  
      else explainActivesProblem()

      res.writeHead 200, "OK"
      res.end()

module.exports = ci
