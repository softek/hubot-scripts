room = process.env.HUBOT_CI_ROOM
ci_host = process.env.CI_HOST

ci = (robot) ->
   robot.respond /(What( is|\'s|s) (.*)('s)? imprint[?]?/i, (msg) ->
      active = msg.match[1]
      if !robot.brain.imprints[active.toLowerCase()]?
         msg.send "There's no record of an active by the name of #{active}."
      else
         msg.send "#{active} is imprinted with #{robot.brain.imprints[active]}"

   robot.respond /imprint (.*) with (.*)/i, (msg) ->
      active = msg.match[1]
      robot.brain.imprints ||= {}
      robot.brain.imprints[active.toLowerCase()] = msg.match[2]    

   robot.respond /wipe (.*)/i, (msg) ->
      active = msg.match[1]

      if !active?
         msg.send 'What Active did you mean?' 
         return

      if !robot.brain.imprints[active.toLowerCase()]?
         msg.send 'Sorry, you must specify the imprint for #{active}\'s engagement.'
      else
         imprint = robot.brain.imprints[active.toLowerCase()]
         msg.send "Wiping #{active}. Imprinting #{imprint}."
   
   robot.router.get '/next-engagement/{active}', (req, res) ->
      active = req.params.active  

      if !robot.brain.imprints[active.toLowerCase()]?
         res.writeHead 404, 'Not Found'
         res.write 'You are not scheduled for an engagement.'
         robot.messageRoom "Hey! #{active} is looking for their next imprint but I didn't know what to do."
      else
         res.writeHead 200, 'OK'
         res.write robot.brain.imprints[active.toLowerCase()]
      res.end()

   robot.router.post '/engagement-complete', (req, res) ->
      active = req.body.active
      imprint = req.body.imprint

      robot.messageRoom room, "#{active}: \"Did I fall asleep?\""
      robot.messageRoom room, 'Yes #{active}, just while #{imprint} was uploading.'
      res.writeHead 200, 'OK'
      res.end()

module.exports = ci
