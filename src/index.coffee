"use strict"

config = require './config'

reloading = false
localConfig = null
buildDone = false
mimosaServer = null
mimosaLiveReload = null
logger = null

registration = (mimosaConfig, register) ->
  return unless mimosaConfig.isServer

  logger = mimosaConfig.log

  mimosaServer = mimosaConfig.installedModules['mimosa-server']
  if not mimosaServer
    return logger.error "mimosa-server-reload is configured but cannot be used unless mimosa-server installed and configured."

  return if mimosaConfig.server.defaultServer.enabled

  mimosaLiveReload = mimosaConfig.installedModules['mimosa-live-reload']

  register ['postBuild'], 'afterServer', _watchServerSource

_watchServerSource = (mimosaConfig, options, next) =>
  watcher = null

  _ = require 'lodash'
  localConfig = _.clone(mimosaConfig, true)

  ignoreFunct = (name) ->
    if mimosaConfig.serverReload.excludeRegex?
      return true if name.match(mimosaConfig.serverReload.excludeRegex)
    if mimosaConfig.serverReload.exclude?
      return true if mimosaConfig.serverReload.exclude.indexOf(name) > -1
    false

  for folder in mimosaConfig.serverReload.watch
    if watcher?
      watcher.add(folder)
    else
      watch = require 'chokidar'
      watcher = watch.watch(folder, {ignored: ignoreFunct, persistent: true})
      watcher.on 'add', (path) -> if buildDone then __reload path
      watcher.on 'change', (path) -> if buildDone then __reload path
      watcher.on 'unlink', (path) -> __reload path
      watcher.on 'error', (error) ->
        # just capturing error, not doing anything with it

  setTimeout(( -> buildDone = true), 200)

  next()

__reload = (path) ->
  logger.debug "Going to reload because of [[ #{path} ]]"
  if not reloading
    reloading = true
    setTimeout((-> __cleanNodeCache(path)), 25)

__cleanNodeCache = (path) ->
  # Deleting all project related entries from cache
  Object.keys(require.cache).forEach (key) ->
    if key.indexOf(localConfig.root) is 0
      logger.debug "Removing #{key} from require cache"
      delete require.cache[key]

  if localConfig.serverReload.validate
    try
      require path
    catch err
      reloading = false
      return logger.error "File at [[ #{path} ]] threw error when required so will not perform server-reload: \n #{err}. Is it possible that this file isn't a JavaScript file? You might consider turning validation off."

  __killLiveReload()

__killLiveReload = ->
  if mimosaLiveReload?
    logger.debug "Disconnecting live reload"
    mimosaLiveReload.disconnect()
  __doServerRestart()

__doServerRestart = ->
  logger.debug "Performing server reload"
  options = {}
  mimosaServer.startServer localConfig, options, ->
    logger.debug "Calling refresh live reload"
    __refreshLiveReload options

__refreshLiveReload = (options) ->
  if mimosaLiveReload?
    logger.debug "Reconnecting live reload"
    mimosaLiveReload.connect localConfig, options, __done
  else
    __done()

__done = ->
  logger.debug "Server reloaded"
  reloading = false

module.exports =
  registration: registration
  defaults:     config.defaults
  placeholder:  config.placeholder
  validate:     config.validate