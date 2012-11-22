"use strict"

logger = require 'logmimosa'
watch = require 'chokidar'
_ = require 'lodash'

try
  mimosaServer = require 'mimosa-server'
catch err
  logger.debug "No mimosa-server installed"

try
  mimosaLiveReload = require 'mimosa-live-reload'
catch err
  logger.debug "mimosa-live-reload is not installed."

config = require './config'

reloading = false
localConfig = null
buildDone = false

registration = (mimosaConfig, register) ->
  return unless mimosaConfig.isServer

  if not mimosaServer
    return logger.error "mimosa-server-reload is configured, but mimosa-server module is not installed. Cannot use mimosa-server-reload."

  if mimosaConfig.modules.indexOf('server') is -1 and mimosaConfig.modules.indexOf('mimosa-server') is -1
    return logger.error "mimosa-server-reload is configured, but mimosa-server is not included in your project. Cannot use mimosa-server-reload."

  return if mimosaConfig.server.useDefaultServer

  # Has live reload in install, but not using it for project
  if mimosaLiveReload? and mimosaConfig.modules.indexOf('live-reload') is -1 and mimosaConfig.modules.indexOf('mimosa-live-reload') is -1
    mimosaLiveReload = null

  register ['buildDone'], 'afterServer', _watchServerSource

_watchServerSource = (mimosaConfig, options, next) =>
  watcher = null

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
      return logger.error "File at [[ #{path} ]] threw error when required so will not perform server-reload: \n #{err}"

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