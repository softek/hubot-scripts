spawn = require("child_process").spawn
fs = require('fs')

ci = (robot) ->
   host = process.env.HUBOT_CI_HOST
   user = process.env.HUBOT_CI_HOST_USERNAME
   password = process.env.HUBOT_CI_HOST_PASSWORD

   writeLog = (message) ->
      var dateAndTime = Date().toUTCString();
      stream = fs.createWriteStream logPath, flags: 'a+', encoding: 'utf8', mode: 0644
      stream.write "#{dateAndTime}: #{message}" 
      stream.end()

   wipe = (active, callback) ->
      revert = spawn "vmware-revert", [host, user, password, "illum-qa-#{active.toLowerCase().trim()}"] 
      revert.on "exit", (code) ->
         callback if code is 0 then code else null 

   getImprint = (active) ->
      getImprints()[active.toLowerCase().trim()]
   
   setImprint = (active, memory, parameters) ->
      getImprints()[active.toLowerCase().trim()] = memory: memory, parameters: parameters
   
   getImprints = () ->
      robot.brain.data.imprints ||= {}

   hasImprints = () ->
      Object.keys(getImprints()).length > 0
   
   robot.respond /list (actives|imprints)/i, (msg) ->
      if hasImprints()
         msg.send "#{active}: \"#{imprint.memory}\"" + (" using \"#{imprint.parameters}\"" if imprint.parameters) for active, imprint of getImprints()
      else
         msg.send "There are no actives."

   robot.respond /imprint (.*) with ([^ ]*)(?: using (.*))?/i, (msg) ->
      active = msg.match[1]
      setImprint active, msg.match[2], msg.match[3]    

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]
      
      unless active
         msg.send "What Active did you mean?" 
         return
      
      imprint = getImprint active

      if imprint
         msg.send "Wiping #{active} and imprinting #{imprint.memory}."
         wipe active, (err) ->
            writeLog "Oops! I had trouble starting the wipe for #{active}!" if err
      else
         msg.send "Sorry, #{active} is blank. Give #{active} an imprint with the command: imprint #{active} with <<IMPRINT>>"

   robot.router.get "/next-engagement/:active", (req, res) ->
      active = req.params.active  
      imprint = getImprint active

      if imprint
         res.writeHead 200, "OK"
         res.write JSON.stringify(imprint)
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
