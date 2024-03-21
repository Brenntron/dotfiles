local util = require 'lspconfig'.util

return {
  settings = {
    root_dir = util.root_pattern('coffeesense.config.js', 'Gemfile', 'package.json')
  }
}
