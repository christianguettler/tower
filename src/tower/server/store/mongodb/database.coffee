# @mixin
Tower.Store.MongoDB.Database =
  ClassMethods:
    initialize: (callback) ->
      unless @initialized
        @initialized = true
        env   = @env()
        mongo = @lib()

        if env.url
          url = new Tower.Dispatch.Url(env.url)
          env.name      = url.segments[0] || url.user
          env.host      = url.hostname
          env.port      = url.port
          env.username  = url.user
          env.password  = url.password

        new mongo.Db(env.name, new mongo.Server(env.host, env.port, {})).open (error, client) =>
          throw error if error
          if env.username && env.password
            client.authenticate env.username, env.password, (error) =>
              throw error if error
              @database = client
              callback() if callback
          else
            @database = client
            callback() if callback

        process.on "exit", =>
          @database.close() if @database
      else
        callback() if callback
        
      @database
    
    # Drop the database and recreate it
    reset: (callback) ->
      return callback.call @ unless @database
      
      @database.dropDatabase =>
        callback.apply @, arguments

  collection: ->
    unless @_collection
      lib = @constructor.lib()
      @_collection = new lib.Collection(@constructor.database, @name)

    @_collection
    
  transaction: (callback) ->
    @_transaction = true
    callback.call @
    @_transaction = false

module.exports = Tower.Store.MongoDB.Database
