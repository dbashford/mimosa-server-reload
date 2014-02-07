"use strict"

fs = require 'fs'

exports.defaults = ->
  serverReload:
    watch:["server.coffee", "server.js", "server.ls", "server.iced", "routes", "src", "lib"]
    exclude:[]
    validate:true

exports.placeholder = ->
  """
  \t

    # serverReload:          # Configuration for automatically restarting a user's server. Used in
                             # conjunction with the 'mimosa-server' module.
      ###
      # "watch" is an array of strings, folders and files whose contents trigger a server reload when
      # they are changed.  Can be relative to the base of the project or can be absolute
      ###
      # watch: ["server.coffee", "server.js", "server.ls", "server.iced", "routes", "src", "lib"]
      # exclude:[]           # An array of regexs or strings that match files to exclude from
                             # reloading the server. Can be a mix of regex and strings. Strings
                             # should be a path relative to the base of the project (location of
                             # mimosa-config) or absolute. ex: [/\.txt$/,"src/README.md"]
      # validate: true       # set validate to false if you do not want Mimosa to validate that the
                             # changed files inside 'watch' are safe to use. If you, for instance,
                             # write not-compilable CoffeeScript inside one of the 'folder's, when
                             # Mimosa restarts your server, your server will fail and Mimosa will
                             # error out. Turn validation off if you are running live reload on
                             # non-JavaScript files, like your server views.

  """

exports.validate = (config, validators) ->
  errors = []
  if validators.ifExistsIsObject(errors, "serverReload config", config.serverReload)

    if config.serverReload.watch?
      if Array.isArray(config.serverReload.watch)
        newFolders = []
        for folder in config.serverReload.watch
          if typeof folder is "string"
            newFolderPath = validators.determinePath folder, config.root
            if fs.existsSync newFolderPath
              newFolders.push newFolderPath
          else
            errors.push "serverReload.watch must be an array of strings."
        config.serverReload.watch =  newFolders
      else
        errors.push "serverReload.watch must be an array."
    else
      errors.push "serverReload.watch must be present."

    validators.ifExistsFileExcludeWithRegexAndString(errors, "serverReload.exclude", config.serverReload, config.root)
    validators.booleanMustExist(errors, "serverReload.validate", config.serverReload.validate)

  errors
