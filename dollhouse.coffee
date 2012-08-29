room = process.env.HUBOT_CI_ROOM

ci = (robot) ->

   getImprint = (active) ->
      robot.brain.imprints ||= {}
      robot.brain.imprints[active.toLowerCase()]

   robot.respond /what(?: is|\'s|s) (\w+)'?s imprint[?]?/i, (msg) ->
      active = msg.match[1]
      imprint = getImprint active

      if imprint
         msg.send "#{active} is imprinted with #{imprint}"
      else
         msg.send "There's no record of an active by the name of #{active}."

   robot.respond /imprint (.*) with (.*)/i, (msg) ->
      active = msg.match[1]
      robot.brain.imprints[active.toLowerCase()] = msg.match[2]    

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]
      
      unless active
         msg.send 'What Active did you mean?' 
         return
      
      imprint = getImprint active

      if imprint
         msg.send "Wiping #{active}. Imprinting #{imprint}."
      else
         msg.send 'Sorry, #{active} is blank. Give #{active} an imprint with the command: imprint #{active} with <<IMPRINT>>'

   robot.router.get '/next-engagement/{active}', (req, res) ->
      active = req.params.active  
      imprint = getImprint active

      if imprint
         res.writeHead 200, 'OK'
         res.write robot.brain.imprints[active.toLowerCase()]
      else
         res.writeHead 404, 'Not Found'
         res.write 'You are not scheduled for an engagement.'
         robot.messageRoom "Hey! #{active} is looking for their next imprint but I didn't know what to do."

      res.end()

   robot.router.post '/engagement-complete', (req, res) ->
      active = req.body.active
      imprint = req.body.imprint

      robot.messageRoom room, "#{active}: \"Did I fall asleep?\""
      robot.messageRoom room, 'Yes #{active}, just while #{imprint} was uploading.'
      res.writeHead 200, 'OK'
      res.end()

module.exports = ci
