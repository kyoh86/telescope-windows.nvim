local windows_b = require "telescope._extensions.windows_builtin"
local windows_c = require "telescope._extensions.windows_config"

local config = windows_c.default()

local function list(opts)
  opts = windows_c.merge(config, opts or {})
  windows_b.windows(opts)
end

return require("telescope").register_extension {
  setup = function(ext_config)
    config = windows_c.merge(config, ext_config)
  end,
  exports = {
    windows = list,
    list = list
  }
}
