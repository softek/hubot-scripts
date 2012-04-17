# Polite.
#
# Say thanks to your robot.

responses = [
  "You're welcome.",
  "No problem.",
  "Anytime.",
  "That's what I'm here for!",
  "You are more than welcome.",
  "You don't have to thank me, I'm your loyal servant.",
  "Don't mention it."
]

shortResponses = [
  'yw',
  'np',
]

farewellResponses = [
  'Goodbye',
  'Have a good evening',
  'Bye',
  'Take care',
  'Nice speaking with you',
  'See you later'
]

isTalkingToMe = (msg, robot) ->
  input = msg.text.toLowerCase()
  name = robot.name.toLowerCase()
  input.indexOf(name) != -1

module.exports = (robot) ->
  robot.hear /(thanks|thank you|cheers|nice one)/i, (msg) ->
    msg.reply msg.random responses if isTalkingToMe(msg, robot)

  robot.hear /(ty|thx)/i, (msg) ->
    msg.reply msg.random shortResponses if isTalkingToMe(msg, robot)

  robot.hear /(hello|hi|sup|howdy|good (morning|evening|afternoon))/i, (msg) ->
    msg.reply "#{robot.name} at your service!" if isTalkingToMe(msg, robot)
    
  robot.hear /(bye|night|goodbye|good night)/i, (msg) ->
    msg.reply msg.random farewellResponses if isTalkingToMe(msg, robot)
