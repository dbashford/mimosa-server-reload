"use strict";
var buildDone, config, localConfig, logger, mimosaLiveReload, mimosaServer, registration, reloading, __cleanNodeCache, __doServerRestart, __done, __killLiveReload, __refreshLiveReload, __reload, __serverRestart, _watchServerSource;

config = require('./config');

reloading = false;

localConfig = null;

buildDone = false;

mimosaServer = null;

mimosaLiveReload = null;

logger = null;

registration = function(mimosaConfig, register) {
  if (!mimosaConfig.isServer) {
    return;
  }
  logger = mimosaConfig.log;
  mimosaServer = mimosaConfig.installedModules['mimosa-server'];
  if (!mimosaServer) {
    return logger.error("mimosa-server-reload is configured but cannot be used unless mimosa-server installed and configured.");
  }
  if (mimosaConfig.server.defaultServer.enabled) {
    return;
  }
  mimosaLiveReload = mimosaConfig.installedModules['mimosa-live-reload'];
  return register(['postBuild'], 'afterServer', _watchServerSource);
};

_watchServerSource = (function(_this) {
  return function(mimosaConfig, options, next) {
    var folder, ignoreFunct, watch, watcher, _i, _len, _ref;
    watcher = null;
    localConfig = mimosaConfig;
    ignoreFunct = function(name) {
      if (mimosaConfig.serverReload.excludeRegex != null) {
        if (name.match(mimosaConfig.serverReload.excludeRegex)) {
          return true;
        }
      }
      if (mimosaConfig.serverReload.exclude != null) {
        if (mimosaConfig.serverReload.exclude.indexOf(name) > -1) {
          return true;
        }
      }
      return false;
    };
    _ref = mimosaConfig.serverReload.watch;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      folder = _ref[_i];
      if (watcher != null) {
        watcher.add(folder);
      } else {
        watch = require('chokidar');
        watcher = watch.watch(folder, {
          ignored: ignoreFunct,
          persistent: true
        });
        watcher.on('add', function(path) {
          if (buildDone) {
            return __reload(path);
          }
        });
        watcher.on('change', function(path) {
          if (buildDone) {
            return __reload(path);
          }
        });
        watcher.on('unlink', function(path) {
          return __reload(path);
        });
        watcher.on('error', function(error) {});
      }
    }
    setTimeout((function() {
      return buildDone = true;
    }), 200);
    return next();
  };
})(this);

__reload = function(path) {
  logger.debug("Going to reload because of [[ " + path + " ]]");
  if (!reloading) {
    reloading = true;
    return setTimeout((function() {
      return __cleanNodeCache(path);
    }), 25);
  }
};

__cleanNodeCache = function(path) {
  var err;
  Object.keys(require.cache).forEach(function(key) {
    if (key.indexOf(localConfig.root) === 0) {
      logger.debug("Removing " + key + " from require cache");
      return delete require.cache[key];
    }
  });
  if (localConfig.serverReload.validate) {
    try {
      require(path);
    } catch (_error) {
      err = _error;
      reloading = false;
      return logger.error("File at [[ " + path + " ]] threw error when required so will not perform server-reload: \n " + err + ". Is it possible that this file isn't a JavaScript file? You might consider turning validation off.");
    }
  }
  return __killLiveReload();
};

__killLiveReload = function() {
  if (mimosaLiveReload != null) {
    logger.debug("Disconnecting live reload");
    mimosaLiveReload.disconnect();
  }
  return __doServerRestart();
};

__doServerRestart = function() {
  var _ref;
  if ((_ref = localConfig.server.userServerFile) != null ? _ref.preMimosaRestart : void 0) {
    logger.debug("Calling preMimosaRestart on server");
    return localConfig.server.userServerFile.preMimosaRestart(__serverRestart);
  } else {
    return __serverRestart();
  }
};

__serverRestart = function() {
  var options;
  options = {};
  logger.debug("Performing server reload");
  return mimosaServer.startServer(localConfig, options, function() {
    logger.debug("Calling refresh live reload");
    return __refreshLiveReload(options);
  });
};

__refreshLiveReload = function(options) {
  if (mimosaLiveReload != null) {
    logger.debug("Reconnecting live reload");
    return mimosaLiveReload.connect(localConfig, options, __done);
  } else {
    return __done();
  }
};

__done = function() {
  logger.debug("Server reloaded");
  return reloading = false;
};

module.exports = {
  registration: registration,
  defaults: config.defaults,
  placeholder: config.placeholder,
  validate: config.validate
};
