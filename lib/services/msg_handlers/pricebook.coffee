exports.run = (msg, done) ->
  console.log "hitting the pricebook msg handler"
  # here i want to send the file from s3 to user's sftp /send 
  done null, 'ok'