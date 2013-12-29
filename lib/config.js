"use strict";
var fs, logger;

fs = require('fs');

logger = require('logmimosa');

exports.defaults = function() {
  return {
    serverReload: {
      watch: ["server.coffee", "server.js", "server.ls", "server.iced", "routes", "src", "lib"],
      exclude: [],
      validate: true
    }
  };
};

exports.placeholder = function() {
  return "\t\n\n  # serverReload:          # Configuration for automatically restarting a user's server. Used in\n                           # conjunction with the 'mimosa-server' module.\n    ###\n    # \"watch\" is an array of strings, folders and files whose contents trigger a server reload when\n    # they are changed.  Can be relative to the base of the project or can be absolute\n    ###\n    # watch: [\"server.coffee\", \"server.js\", \"server.ls\", \"server.iced\", \"routes\", \"src\", \"lib\"]\n    # exclude:[]           # An array of regexs or strings that match files to exclude from\n                           # reloading the server. Can be a mix of regex and strings. Strings\n                           # should be a path relative to the base of the project (location of\n                           # mimosa-config) or absolute. ex: [/\.txt$/,\"src/README.md\"]\n    # validate: true       # set validate to false if you do not want Mimosa to validate that the\n                           # changed files inside 'watch' are safe to use. If you, for instance,\n                           # write not-compilable CoffeeScript inside one of the 'folder's, when\n                           # Mimosa restarts your server, your server will fail and Mimosa will\n                           # error out. Turn validation off if you are running live reload on\n                           # non-JavaScript files, like your server views.\n";
};

exports.validate = function(config, validators) {
  var errors, folder, newFolderPath, newFolders, _i, _len, _ref;
  errors = [];
  if (validators.ifExistsIsObject(errors, "serverReload config", config.serverReload)) {
    if (config.serverReload.watch != null) {
      if (Array.isArray(config.serverReload.watch)) {
        newFolders = [];
        _ref = config.serverReload.watch;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          folder = _ref[_i];
          if (typeof folder === "string") {
            newFolderPath = validators.determinePath(folder, config.root);
            if (fs.existsSync(newFolderPath)) {
              newFolders.push(newFolderPath);
            }
          } else {
            errors.push("serverReload.watch must be an array of strings.");
          }
        }
        config.serverReload.watch = newFolders;
      } else {
        errors.push("serverReload.watch must be an array.");
      }
    } else {
      errors.push("serverReload.watch must be present.");
    }
    validators.ifExistsFileExcludeWithRegexAndString(errors, "serverReload.exclude", config.serverReload, config.root);
    validators.booleanMustExist(errors, "serverReload.validate", config.serverReload.validate);
  }
  return errors;
};
