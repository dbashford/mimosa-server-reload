"use strict";
var fs;

fs = require('fs');

exports.defaults = function() {
  return {
    serverReload: {
      watch: ["server.coffee", "server.js", "server.ls", "server.iced", "routes", "src", "lib"],
      exclude: [],
      validate: true
    }
  };
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
