"use strict"

fs = require 'fs'
path = require 'path'

windowsDrive = /^[A-Za-z]:\\/

exports.defaults = ->
  serverReload:
    folders:["src", "lib", "routes"]
    exclude:[]
    validate:true

exports.placeholder = ->
  """
  \t

    # serverReload:                         # Configuration for automatically restarting a user's
                                            # server.  Used in conjunction with the
                                            # 'mimosa-server' module.
      # folders: ["src", "lib", "routes"]   # A list of folders whose contents trigger a server
                                            # reload when they are changed.  Can be relative to the
                                            # base of the project (location of mimosa-config) or can
                                            # be absolute
      # exclude:[]                          # An array of regexs or strings that match files to
                                            # exclude from reloading the server. Can be a mix of
                                            # regex and strings. Strings should be a path relative
                                            # to the base of the project (location of mimosa-config)
                                            # or absolute.
                                            # ex: [/\.txt$/,"src/README.md"]
      # validate: true                      # set validate to false if you do not want Mimosa to
                                            # validate that the changed files inside 'folders' are
                                            # safe to use.  If you, for instance, write not-
                                            # compilable CoffeeScript inside one of the 'folder's,
                                            # when Mimosa restarts your server, your server will
                                            # fail and Mimosa will error out.


  """

exports.validate = (config) ->
  errors = []
  if config.serverReload?
    serverReload = config.serverReload
    if typeof config.minify is "object" and not Array.isArray(config.minify)

      if serverReload.folders?
        if Array.isArray(serverReload.folders)
          newFolders = []
          for folder in serverReload.folders
            if typeof folder is "string"
              newFolderPath = __determinePath folder, config.root
              if fs.existsSync newFolderPath
                newFolders.push newFolderPath
              else
                errors.push "serverReload.folders paths must exist, could not find [[ #{folder} ]]."
            else
              errors.push "serverReload.folders must be an array of strings."
          serverReload.folders =  newFolders
        else
          errors.push "serverReload.folders must be an array."
      else
        errors.push "serverReload.folders must be present."

      if serverReload.exclude?
        if Array.isArray(serverReload.exclude)
          regexes = []
          newExclude = []
          for exclude in serverReload.exclude
            if typeof exclude is "string"
              newExclude.push __determinePath exclude, config.root
            else if exclude instanceof RegExp
              regexes.push exclude.source
            else
              errors.push "serverReload.exclude must be an array of strings and/or regexes."
              break

          if regexes.length > 0
            serverReload.excludeRegex = new RegExp regexes.join("|"), "i"

          serverReload.exclude = newExclude
        else
          errors.push "serverReload.exclude must be an array."


      if serverReload.validate?
        unless typeof serverReload.validate is "boolean"
          errors.push "serverReload.validate must be a boolean."
      else
        errors.push "serverReload.validate must be present."


    else
      errors.push "serverReload configuration must be an object."

  errors

__determinePath = (thePath, relativeTo) ->
  return thePath if windowsDrive.test thePath
  return thePath if thePath.indexOf("/") is 0
  path.join relativeTo, thePath
