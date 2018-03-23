consumer = require '../lib/services/rabbitMQ/receive'
heroku = require '../etc/heroku'

priceBookQ = heroku.config.rabbitMq.priceBookQ

consumer.receive_msg priceBookQ, (err, results) ->
  if err?
    console.log err
  else
    console.log results

