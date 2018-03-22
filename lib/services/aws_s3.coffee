aws = require 'aws-sdk'
heroku = require '../../etc/heroku'

access_key_id = heroku.config.aws.access_key_id 
secret_access_key = heroku.config.aws.secret_access_key 

aws.config.update({accessKeyId: access_key_id, secretAccessKey: secret_access_key})

exports.awsTransferUpload = (options, done) ->
  throw "no required options" unless options
  try 
    s3 = new aws.S3({apiVersion: '2006-03-01'})

    params =
      Bucket: options.bucket
      Key: options.key
      Body: options.body

    s3.putObject params, (err, data) ->
      done err, data    

exports.awsGetObject = (options, done) ->
  throw "no required options" unless options
  try 
    s3 = new aws.S3({apiVersion: '2006-03-01'})

    params =
      Bucket: options.bucket
      Key: options.key

    s3.getObject params, (err, data) ->
      done err, data    

exports.awsMoveObject = (options, done) ->
  # i need to do cp and delete here
  # options = 
  #   des_bucket
  #   des_key
  #   source_path
  #   del_bucket 
  #   del_key

  throw "no required options" unless options
  try
    s3 = new aws.S3({apiVersion: '2006-03-01'})

    params =
      Bucket: options.des_bucket
      CopySource: options.source_path
      Key: options.des_key

    s3.copyObject params, (err, data) ->
      if err?
        done err, null
      else
        p = 
          Bucket: options.del_bucket
          Key: options.del_key

        s3.deleteObject p, (err, data) ->
          done err, 'moved'            

  catch error
    done error, null
