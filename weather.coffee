http = require 'http'

# http://w1.weather.gov/xml/current_obs/seek.php?state=mo&Find=Find#XML
stationId = (process.env.HUBOT_WEATHERSTATION ? "KMCI").toUpperCase()

# http://en.wikipedia.org/wiki/You_talkin'_to_me%3F
youTalkinToMe = (msg, robot) ->
  input = msg.message.text.toLowerCase()
  name = robot.name.toLowerCase()
  input.indexOf(name) != -1

module.exports = (robot) ->
  robot.hear /(?:what|say|describe|tell).*weather/i, (msg) ->
    return unless youTalkinToMe msg, robot
    getWeather (err, xml) ->
      get = (name) ->
        xml.match(new RegExp("<#{name}>(.*?)</#{name}>"))[1]
      text = if err
          'Not sure if I heard right, but it is supposed to be cloudy with a chance of meatballs.\r\n' + err if err?
        else
          "The weather at #{get('location')} is #{get('weather')} at #{get('temp_f')} °F" +
          if get('windchill_f') == get('temp_f') then '' else ", but it feels like #{get('windchill_f')} °F"
      msg.send text

getWeather = (callback) ->
  http.get {host:"w1.weather.gov",path:"/xml/current_obs/#{stationId}.xml"}, (res) ->
    data = ''

    res.on 'data', (chunk) ->
      data += chunk

    res.on 'end', () ->
      callback null, data

    res.on 'error', (err) ->
      callback err ? new Error 'Error checking weather'
