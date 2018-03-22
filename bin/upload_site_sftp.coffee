bs      = require '../lib/bootstrap'
fs      = require 'fs'
path    = require 'path'
heroku  = require '../etc/heroku'
async  = require 'async'
sfpt_service = require '../lib/services/sftp-service'


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
        file_transfer = (site, done) ->
          console.log 'Starting file transfer for site: ' + site.name + ' site id: ' + site.id
          s =
            id: site.id
            name: site.name
            client_id: site.client_id
            pos: site.pos
            sftp:
              host: site.r_host
              port: site.port
              username: site.username
              password: site.password
              source: site.source_dir
              validation: site.file_type

          sfpt_service.get_sftp_files s, (err, results) ->
            if err?
              done null, 'ok'
              console.log err
            else
              done null, results

        async.eachLimit rows, heroku.config.parallel.uploadSites, file_transfer, (err, res) ->
          console.log 'file upload process complete'
          if err?
            console.log 'this is main function'
            console.log err
          else
            setTimeout upload, 45000



upload()
 