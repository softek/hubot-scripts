http = require 'http'
module.exports = (robot) ->
  robot.hear /tell.*(?:a|something) (?:joke|funny)(?: about ([a-z]+\.[a-z]+|me|you))?/i, (msg) ->
    subject = getSubject msg.match[1], msg.message.user.name
    msg.send 'a joke about ' + subject + '...  Let me think about it...' if subject.length
    tellJoke = ->
      getJoke subject, (err, text) ->
        msg.send "Cannot compute.  #{robot.name} is about to die.\r\n#{err}".replace(/e/ig, '3') if err?
        msg.send "I heard a funny one the other day:\r\n#{text}" unless err?
    setTimeout tellJoke, if subject.length then 5000 * Math.random() else 0

  getSubject = (subject, currentUser) ->
    subjectLower = subject.toLowerCase() if subject
    if subjectLower == robot.name.toLowerCase() || subjectLower == 'you'
      robot.name + '.softekinc_com'
    else if subjectLower == 'me'
      currentUser
    else if (subjectLower ? '').indexOf('.') > 0
      subject
    else
      ''

  getJoke = (firstDotLast, callback) ->
    query =
      if (firstDotLast ? '').indexOf('.') > 0
        fl = firstDotLast.split('.')
        first = fl[0]
        last = fl[1]
        "&firstName=#{first}&lastName=#{last}"
      else
        ''
    
    reformat = (text) ->
      norris = /\b(blood|death|pain|round-?house|kick(ing|ed|s|)|grinds|rage|die|brutal|lethal|weapon|kill|bullet|eat|gun|ate|fecal)\b/i
      skeet = /\b(?:class|factory|pattern|instantiate|interfaces|reflection|stand-up|pi|iTunes|installing|Quicktime|machine|infinite|loop|DDOS|GUI|programming|languages|keyboard|type-cast|Compiler|protocol|code|Turing|dereference|NULL|sudo|equality)/i
      text = text.replace(/chuck/ig, 'Jon').replace(/Norris/ig, 'Skeet') + '\r\nOr was that Chuck Norris?' if skeet.test text unless norris.test text
      text

    http.get {host:"api.icndb.com", path:'/jokes/random?exclude=explicit' + query}, (res) ->
      data = ''

      res.on 'data', (chunk) ->
        data += chunk

      res.on 'end', () ->
        joke = JSON.parse data
        callback null, reformat joke.value.joke

      res.on 'error', (err) ->
        callback err ? new Error 'Error getting answer from youtrack'
