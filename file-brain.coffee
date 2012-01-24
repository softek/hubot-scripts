Url  = require "url"
fs   = require 'fs'
path = require 'path'


# sets up hooks to persist the brain into file.
module.exports = (robot) ->
  brainPath   = process.env.FILE_BRAIN_PATH || '/var/hubot/brain'
  brainPath   = path.join brainPath, 'brain'

  console.log "reading file #{brainPath} to populate brain"
  
  fs.readFile brainPath, (err, data) ->
    if err
      return
    else if data
      robot.brain.mergeData JSON.parse(data.toString())
      robot.brain.emit 'load', robot.brain.data

  robot.brain.on 'save', (data) ->
    fs.writeFile brainPath, JSON.stringify(data), () ->
      return
