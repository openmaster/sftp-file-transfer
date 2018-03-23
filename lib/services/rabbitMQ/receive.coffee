amqp = require 'amqplib/callback_api'
rabbit = require './send'
config = require("../../config.coffee").config()
heroku = require '../../../etc/heroku'

ingestorQ = heroku.config.rabbitMq.ingestorQ
errorQ = heroku.config.rabbitMq.errorQ
rabbitMQ = heroku.config.rabbitMq.connect

handlers = 
  'INGESTOR': require '../msg_handlers/ingestors'
  'ERRORS': require '../msg_handlers/error'

process_msgs = (msg, cb) ->
  try
    console.log '-------------- Processing MSG --------------------'
    m = JSON.parse(msg.content.toString())
    msg_handler = handlers[m.service.toUpperCase()]
    if msg_handler?
      handlers[m.service.toUpperCase()].run m, (err, r) ->  
        cb err, r
    else
      console.log ' ***  no msg handler available for service: ' + m.service.toString() 
      er_msg = 'No msg handler available for service: ' + m.service.toString() 
      cb er_msg, null
  catch error 
    console.log error
    cb error, null

exports.receive_msg = (que, done) ->
  try
    console.log 'Connecting to que: ' + que + ' @ ' + rabbitMQ
    amqp.connect rabbitMQ, (err, conn) ->
      if err?
        console.log err
        done err, null
      else
        conn.createChannel (err, ch) ->
          if err?
            console.log err
            done err, null
          else
            ch.assertQueue(que, {durable: true})
            ch.prefetch(1) 
            console.log " ** Waiting for messages in %s Queue", que
            ch.consume que, ((msg) ->
              console.log '------------- NEW MSG -------------------'
              console.log msg.content.toString()
              process_msgs msg, (err, re) ->
                if err?
                  console.log err
                  # generate error msg
                  #Q_msg = 
                  #  service: err.service || 'errors'
                  #  status: err.status || 'general'
                  #  body: err.body || err
                  #  msg: JSON.parse(msg.content.toString())
                  #rabbit.send_msg errorQ, JSON.stringify(Q_msg), (err, r) ->
                  ch.ack msg
                  #done null, err
                else
                  ch.ack msg
                  #done null, re
            )
  catch error
    done error, null

