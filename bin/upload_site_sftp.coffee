bs      = require '../lib/bootstrap'
fs      = require 'fs'
path    = require 'path'

config_path = path.join __dirname, '..', 'etc', 'dev.json'
config  = JSON.parse fs.readFileSync config_path, 'utf-8'

upload = ->
  bs.setup config, (err, db) ->
    console.log 'get the bootstrap done'

upload()
 