require "options"
require "Lazy"
require "keymaps"
require "autocommands"

local commands = require "commands"
commands.load(commands.defaults)

vim.notify = require 'notify'
