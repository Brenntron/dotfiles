require "options"
require "keymaps"
require "autocommands"
require "Lazy"

local Log = require "utils.log"
Log:debug "Starting Neovim"

local commands = require "commands"
commands.load(commands.defaults)
