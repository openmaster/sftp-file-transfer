// Generated by CoffeeScript 1.7.1
(function() {
  var Client, Pool, fs, pg_convert, postgres_database_connection_string, setup, _, _ref;

  fs = require('fs');

  _ref = require('pg'), Pool = _ref.Pool, Client = _ref.Client;

  _ = require('underscore');

  exports.postgres_database_connection_string = postgres_database_connection_string = function(config) {
    var _ref1;
    console.log('bootstraping....');
    if (((_ref1 = process.env) != null ? _ref1.DATABASE_URL : void 0) != null) {
      return process.env.DATABASE_URL;
    } else {
      return "postgres://" + config.database.uid + ":" + config.database.pwd + "@" + config.database.host + ":" + config.database.port + "/" + config.database.name;
    }
  };

  pg_convert = function(results) {
    var fld, row, _i, _j, _len, _len1, _ref1, _ref2;
    _ref1 = results.rows;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      row = _ref1[_i];
      _ref2 = results.fields;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        fld = _ref2[_j];
        if (fld.dataTypeID === 1700) {
          if (row[fld.name] != null) {
            row[fld.name] = parseFloat(row[fld.name]);
          }
        }
        if (fld.dataTypeID === 20) {
          if (row[fld.name] != null) {
            row[fld.name] = parseInt(row[fld.name]);
          }
        }
      }
    }
    return results.rows;
  };

  exports.setup = setup = function(config, done) {
    var connect_db, connection_string, pooled_client;
    connection_string = postgres_database_connection_string(config);
    console.log(connection_string);
    pooled_client = {
      query: function(statement, params, cb) {
        var p;
        if (cb == null) {
          cb = params;
        }
        p = new Client({
          connectionString: connection_string,
          ssl: true
        });
        return p.connect(function(err, client, done) {
          if (err) {
            throw "error retrieving connection from pool " + err.toString();
          } else {
            return client.query(statement, params, function(err, result) {
              done;
              return cb(err, result);
            });
          }
        });
      },
      rows: function(sql, params, cb) {
        if (!_.isArray(params)) {
          throw "params must be an array";
        }
        return this.query(sql, params, function(err, results) {
          var rows;
          if (err != null) {
            logger.error(err.toString());
            return cb(err, null);
          } else {
            rows = pg_convert(results);
            return cb(null, rows);
          }
        });
      },
      row: function(sql, params, cb) {
        if (!_.isArray(params)) {
          throw "params must be an array";
        }
        return this.query(sql, params, function(err, results) {
          var rows;
          if (err != null) {
            logger.error(err.toString());
            return cb(err, null);
          } else {
            rows = pg_convert(results);
            if (rows.length === 0) {
              return cb(null, null);
            } else if (rows.length === 1) {
              return cb(null, rows[0]);
            } else {
              logger.warn("sql statement returned more than one row");
              return cb(null, rows[0]);
            }
          }
        });
      },
      end: function() {
        return pool.end();
      }
    };
    connect_db = function(cb) {
      return cb(null, pooled_client);
    };
    return connect_db(function(err, db) {
      return done(err, db);
    });
  };

}).call(this);