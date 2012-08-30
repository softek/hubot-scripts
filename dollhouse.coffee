spawn = require("child_process").spawn

ci = (robot) ->
   room = process.env.HUBOT_CI_ROOM
   host = process.env.HUBOT_CI_HOST
   user = process.env.HUBOT_CI_HOST_USERNAME
   password = process.env.HUBOT_CI_HOST_PASSWORD

   wipe = (active) ->
      spawn "vmware-revert", [host, user, password, "illum-qa-#{active.toLowerCase().trim()}"] 

   getImprint = (active) ->
      getImprints()[active.toLowerCase().trim()]
   
   setImprint = (active, imprint) ->
      getImprints()[active.toLowerCase().trim()] = imprint
   
   getImprints = () ->
      robot.brain.data.imprints ||= {}

   hasImprints = () ->
      Object.keys(getImprints()).length > 0
   
   robot.respond /list (actives|imprints)/i, (msg) ->
      if hasImprints()
         msg.send "#{active}: #{imprint}" for active, imprint of getImprints()
      else
         msg.send "There are no actives."

   robot.respond /what(?: is|\'s|s) (\w+)'?s imprint[?]?/i, (msg) ->
      active = msg.match[1]
      imprint = getImprint active

      if imprint
         msg.send "#{active} is imprinted with #{imprint}"
      else
         msg.send "There's no record of an active by the name of #{active}."

   robot.respond /imprint (.*) with (.*)/i, (msg) ->
      active = msg.match[1]
      setImprint active, msg.match[2]    

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]
      
      unless active
         msg.send "What Active did you mean?" 
         return
      
      imprint = getImprint active

      if imprint
         msg.send "Wiping #{active}. Imprinting #{imprint}."
         wipe active
      else
         msg.send "Sorry, #{active} is blank. Give #{active} an imprint with the command: imprint #{active} with <<IMPRINT>>"

   robot.router.get "/next-engagement/:active", (req, res) ->
      active = req.params.active  
      imprint = getImprint active

      if imprint
         res.writeHead 200, "OK"
         res.write imprint
      else
         res.writeHead 404, "Not Found"
         res.write "You are not scheduled for an engagement."
         robot.messageRoom "Hey! #{active} is looking for their next imprint but I didn't know what to do."

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

      reportActivesSuccess() if reported.status is "success" else explainActivesProblem()

      res.writeHead 200, "OK"
      res.end()

module.exports = ci
