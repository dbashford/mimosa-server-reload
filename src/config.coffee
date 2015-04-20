"use strict"

fs = require 'fs'

exports.defaults = ->
  serverReload:
    watch:["server.coffee", "server.js", "server.ls", "server.iced", "routes", "src", "lib"]
    exclude:[]
    validate:true

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
