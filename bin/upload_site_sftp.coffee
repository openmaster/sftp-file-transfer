bs      = require '../lib/bootstrap'
fs      = require 'fs'
path    = require 'path'

config_path = path.join __dirname, '..', 'etc', 'dev.json'
config  = JSON.parse fs.readFileSync config_path, 'utf-8'

upload = ->
  bs.setup config, (err, db) ->
    console.log 'get the bootstrap done'
    if err?
      console.log err
    else
      db.rows "select * from core.sites s join core.site_sftp_setting ss on s.id = ss.site_id where ss.disabled is not true", [], (err, rows) ->
        if err?
          console.log err
        else
          console.log rows

upload()
 