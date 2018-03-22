fs      = require 'fs'
pg      = require 'pg'
_       = require 'underscore'


exports.postgres_database_connection_string = postgres_database_connection_string = (config) ->
  console.log 'bootstraping....'
  if process.env?.DATABASE_URL?
    process.env.DATABASE_URL
  else
    "postgres://#{config.database.uid}:#{config.database.pwd}@#{config.database.host}:#{config.database.port}/#{config.database.name}"


exports.setup = setup = (config, done) ->
  connection_string = postgres_database_connection_string config
  console.log connection_string 
  done null, 'ok'