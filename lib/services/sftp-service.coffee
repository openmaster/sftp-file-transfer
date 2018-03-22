client = require 'ssh2-sftp-client'
aws      = require './aws_s3'
async    = require 'async'
path     = require 'path'
rabbit_mq = require './rabbitMQ/send'
_         = require 'underscore'
heroku    = require '../../etc/heroku'
fs	  = require 'fs'

ingestorQ = heroku.config.rabbitMq.ingestorQ
errorQ = heroku.config.rabbitMq.errorQ

shiftBucket = heroku.config.aws.shiftBucket


# dump directory name
dump = 
  dirname: 'backup'

exports.send_sftp_file = (contents, site, done) -> 
  console.log 'hitting sftp service method'
  sc = new client()
  sc.connect({
    host: site.host
    port: site.port
    username: site.username
    password: site.password
  })
  .then((d) ->
    buf = Buffer.from contents.toString(), 'utf8'
    p = path.join './', site.destination_dir.toString(), '/BT9000 Price Book.xml'
    sc.put(buf, p))
  .then((result) -> 
    done null, 'file send ok')
  .catch((err) ->
    console.log err
    done err, null)


exports.test_connection = (body, done) ->
  console.log 'hitting test connection method'
  console.log body
  s = new client()
  s.connect({
      host: body.host
      port: body.port
      username: body.username
      password: body.password 
      PreferredAuthentications: "password"
      PubkeyAuthentication: "no"
      debug: console.log
  })
  .then((d) ->
    console.log 'then' 
    s.list(body.source))
  .then((list) ->
    if list.length < 700
      get_valid_list list, body.validations.toString(), (err, new_list) ->
        s.end()
        if err?
          done null, list
        else
          done null, new_list
    else
      s.end()
      done null, list)
  .catch((err) ->
    console.log 'in catch block'
    s.end()
    done err, null) 



get_dump_hierarchy = (millisec) ->
  t = new Date(1970, 0, 1)
  t.setTime(millisec)
  path.join t.getFullYear().toString(), (t.getMonth() + 1).toString(), t.getDate().toString()

move_to_temp = (sftp, site, file, done) ->

  basic_url = site.sftp.source
  valid = site.sftp.validation
  console.log valid
  console.log file
  file_check file.name, valid, (err, fileType) ->
    if err?
      console.log err
      done err, null
    else
      console.log 'this is file type from moving method : ' + fileType
      f_path = path.join basic_url, file.name
      n_path = path.join basic_url, dump.dirname, fileType, get_dump_hierarchy(file.modifyTime).toString(), file.name
      xsite_path = path.join basic_url, dump.dirname, fileType, get_dump_hierarchy(file.modifyTime).toString(), (Date.now() + 'xsite' + file.name).toString()
      sftp.mkdir(path.join(basic_url, dump.dirname, fileType, get_dump_hierarchy(file.modifyTime)), true)
      .then( ->
        sftp.rename(f_path, n_path)
        .then( -> 
          done null, 'ok')
        .catch((err) ->
          console.log 'renaming file and back up again' 
          sftp.rename(f_path, xsite_path)
          .then( ->
            done null, 'ok')
          .catch((error) ->
            done error, null)
        ))
      .catch((e) ->    
        done e, null)

valid_file = (file_name, expressions) ->  
  file_name.match(/^[0-9]+\.xml/g)


get_all_files = (sftp, site, list, done) ->
  get_file_data = (file, cb) ->
    file_path = path.join site.sftp.source, file.name
    console.log 'getting file: ' + file_path
    sftp.get(file_path)
    .then((data) ->
      fl_data = ''
      data.on 'data', (chunk) ->
        console.log 'getting data chunk: %d for file: %s site: %d', chunk.length, file.name, site.id
        fl_data = fl_data + chunk
      data.on 'end', ->
        console.log 'uploading: ' + file.name
        file_name = path.join site.client_id.toString(), site.id.toString(), 'pending', file.type.toString(), file.name.toString()
        options =
          bucket: shiftBucket
          key: file_name
          body: fl_data.toString()
        aws.awsTransferUpload options, (err, results) ->
          if err?
            console.log options
            console.log err
            Q_msg = 
              client_id: site.client_id.toString()
              site_id: site.id.toString()
              service: 'errors'
              status: 'awsUpload'
              file: file.name.toString()
              bucket: shiftBucket
              body: 'AWS:Error in uploading file: ' + err

            rabbit_mq.send_msg errorQ, JSON.stringify(Q_msg), (err, r) ->
              if err?
                cb err, null
              else
                cb null, 'ok'          
          else
            console.log '-------- Upload complete for: ' + file_name
            move_to_temp sftp, site, file, (err, r) ->
              if err?
                Q_msg = 
                  client_id: site.client_id.toString() 
                  site_id: site.id.toString()
                  service: 'errors'
                  status: 'moveBackup'
                  file: file_name
                  bucket: shiftBucket
                  body: 'Error in file moving to backup folder' + err
              else
                Q_msg = 
                  client_id: site.client_id.toString()
                  site_id: site.id.toString()
                  pos: site.pos
                  dump_her: get_dump_hierarchy(file.modifyTime).toString()
                  service: 'ingestor'
                  status: 'ok'
                  file: file_name
                  bucket: shiftBucket
                  body: 'new file to parse'
              console.log 'queue: ' + ingestorQ  
              rabbit_mq.send_msg ingestorQ, JSON.stringify(Q_msg), (err, r) ->
                if err?
                  console.log err
                  cb err, null
                else
                  cb null, 'ok'
    ).catch((error) ->  cb error, null)

  async.eachLimit list, heroku.config.parallel.uploadFiles, get_file_data, (err) ->
    if err?
      done err, null
    else
      done null, 'ok'


file_check = (name, matcher, cb) ->
  try
    get_match = null
    matchers = matcher.split(",")
    for re in matchers
      m = re.split("@")
      exp = new RegExp(m[1])
      if name.match exp
        get_match = m[0]
    if get_match?
      cb null, get_match
    else
      cb null, null
  catch error
    cb error, null

split_array = (array, n) ->
  if array.length then [array.splice(0, n)].concat(split_array(array, n)) else []

get_valid_list = (list, validations, done) -> 
#  list = _.filter list, (l) ->  l.type == '-'  

  splitList = split_array list, 500
  new_list = []

  check_file_name = (l, cb) ->
    if heroku.config.parallel.uploadAtTimes? and new_list.length > heroku.config.parallel.uploadAtTimes
      async.setImmediate ->
        cb null, 'ok'
    else
      #console.log 'checking file: ' + l.name + ' : ' + file_check(l.name, validations) if file_check(l.name, validations)
      file_check l.name, validations, (err, type) ->
        if type? and type isnt 'undefined' and type isnt null
          l.type = type
          new_list.push l 
          async.setImmediate ->
            cb null, 'ok'
        else
          async.setImmediate ->
            cb null, 'ok'


  run = (li, cb2) ->
    li = _.filter li, (l) ->  l.type == '-'  
    try
      async.eachSeries li, check_file_name, (err) ->
        if err?
          console.log err
          cb2 err, null
        else
          cb2 null, 'ok'
    catch err
      console.log err
      cb2 err, null

  async.eachSeries splitList, run, (err) ->
    if err?
      console.log err
      done err, null
    else
      done null, new_list


exports.get_sftp_files = (site, done) ->
  sftp = new client()

  console.log 'connecting host: ' + site.sftp.host
  sftp.connect({
      host: site.sftp.host
      port: site.sftp.port
      username: site.sftp.username
      password: site.sftp.password 
  }).then((d) ->
    console.log 'connected and getting list of files'
    sftp.list(site.sftp.source)
  ).then((data) ->
    get_valid_list data, site.sftp.validation, (err, new_list) ->
      console.log 'Total Valid files for ' + site.name + ': ' + new_list.length
      if new_list?.length>0
        get_all_files sftp, site, new_list, (err, result) ->
          if err?
            done err, null
          else
            console.log 'successfuly upload all the files for: ' +  site.name + ' sites id: ' + site.id
            done null, result
      else
        console.log 'No files for: ' +  site.name + ' sites id: ' + site.id
        done null, 'ok'
  ).catch((err) ->
    console.log err
    done err, null)

