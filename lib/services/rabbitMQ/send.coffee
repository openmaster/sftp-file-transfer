amqp = require 'amqplib/callback_api'
heroku = require '../../../etc/heroku'

rabbitMQ = heroku.config.rabbitMq.connect.toString()

exports.send_msg = (que, msg, done) ->
  console.log 'Sending msg to Queue %s: ', que
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
          ch.assertQueue que, {durable: true}, (err, ok) ->
            if err?
              console.log err
              done err, null
            else
              ch.sendToQueue que, new Buffer msg, {persistent: true}
              setTimeout (->
                conn.close()
                done null, ok
              ), 1000

