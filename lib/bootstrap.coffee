fs      = require 'fs'
{Pool, Client}  = require 'pg'
_       = require 'underscore'


exports.postgres_database_connection_string = postgres_database_connection_string = (config) ->
  console.log 'bootstraping....'
  if process.env?.DATABASE_URL?
    process.env.DATABASE_URL
  else
    "postgres://#{config.database.uid}:#{config.database.pwd}@#{config.database.host}:#{config.database.port}/#{config.database.name}"

pg_convert = (results) ->
  for row in results.rows
    for fld in results.fields
      if fld.dataTypeID is 1700
        row[fld.name] = parseFloat row[fld.name] if row[fld.name]?
      if fld.dataTypeID is 20
        row[fld.name] = parseInt row[fld.name] if row[fld.name]?
  results.rows

exports.setup = setup = (config, done) ->
  connection_string = postgres_database_connection_string config
  console.log connection_string 

  #Client.defaults.ssl = true
    
  pooled_client =
    query: (statement, params, cb) ->
      cb = params if not cb?
      p = new Client({connectionString: connection_string, ssl: true})

      p.connect (err, client, done) ->
        if err
          throw "error retrieving connection from pool " + err.toString()
        else
          client.query statement, params, (err, result) ->
            done
            cb err, result

    rows: (sql, params, cb) ->
      throw "params must be an array" unless _.isArray params
      @query sql, params, (err, results) ->
        if err?
          logger.error err.toString()
          cb err, null
        else
          rows = pg_convert results
          cb null, rows

    row: (sql, params, cb) ->
      throw "params must be an array" unless _.isArray params
      @query sql, params, (err, results) ->
        if err?
          logger.error err.toString()
          cb err, null
        else
          rows = pg_convert results
          if rows.length is 0
            cb null, null
          else if rows.length is 1
            cb null, rows[0]
          else
            logger.warn "sql statement returned more than one row"
            cb null, rows[0]

    end: -> pool.end()


  connect_db = (cb) ->
    cb null, pooled_client

  connect_db (err, db) ->
    done err, db
  