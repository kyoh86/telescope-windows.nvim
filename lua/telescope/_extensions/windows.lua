local actions = require "telescope.actions"
local conf = require "telescope.config".values
local finders = require "telescope.finders"
local Path = require("plenary.path")
local pickers = require "telescope.pickers"
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")

local function show_entry_window(prompt_bufnr)
  local entry = actions.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local winnr = entry.winnr
  vim.api.nvim_set_current_win(winnr)
end

local M = {}

function M.gen_from_window(opts)
  opts = opts or {}

  local disable_devicons = opts.disable_devicons

  local icon_width = 0
  if not disable_devicons then
    local icon, _ = utils.get_devicons("fname", disable_devicons)
    icon_width = utils.strdisplaywidth(icon)
  end

  local displayer =
    entry_display.create {
    separator = " ",
    items = {
      {width = opts.tabpage_width},
      {width = opts.winnr_width},
      {width = 4},
      {width = icon_width},
      {remaining = true}
    }
  }

  local cwd = vim.fn.expand(opts.cwd or vim.fn.getcwd())

  local make_display = function(entry)
    local display_bufname
    if opts.shorten_path then
      display_bufname = Path:new({entry.filename}):shorten()
    else
      display_bufname = entry.filename
    end

    local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)

    return displayer {
      {entry.tabpage, "TelescopeResultsNumber"},
      {entry.winnr, "TelescopeResultsNumber"},
      {entry.indicator, "TelescopeResultsComment"},
      {icon, hl_group},
      display_bufname .. ":" .. entry.lnum
    }
  end

  return function(entry)
    local bufname = entry.info.name ~= "" and entry.info.name or "[No Name]"
    -- if bufname is inside the cwd, trim that part of the string
    bufname = Path:new({bufname}).normalize(cwd)

    local hidden = entry.info.hidden == 1 and "h" or "a"
    local readonly = vim.api.nvim_buf_get_option(entry.bufnr, "readonly") and "=" or " "
    local changed = entry.info.changed == 1 and "+" or " "
    local indicator = entry.flag .. hidden .. readonly .. changed

    return {
      valid = true,
      value = bufname,
      ordinal = entry.winnr .. " : " .. bufname,
      display = make_display,
      tabpage = entry.tabpage,
      winnr = entry.winnr,
      bufnr = entry.bufnr,
      filename = bufname,
      lnum = entry.info.lnum ~= 0 and entry.info.lnum or 1,
      indicator = indicator
    }
  end
end

M.windows = function(opts)
  local winnrs =
    vim.tbl_filter(
    function(w)
      local win_conf = vim.api.nvim_win_get_config(w)
      if win_conf.relative ~= "" and not win_conf.focusable then
        return false
      end
      if opts.ignore_current_window and w == vim.api.nvim_get_current_win() then
        return false
      end
      return true
    end,
    vim.api.nvim_list_wins()
  )

  if not next(winnrs) then
    return
  end

  local windows = {}
  local default_selection_idx = 1

  local max_tabpage = 0
  local max_winnr = 0
  for _, winnr in ipairs(winnrs) do
    local flag = winnr == vim.api.nvim_get_current_win() and "%" or " "

    local tabpage = vim.api.nvim_win_get_tabpage(winnr)
    local bufnr = vim.fn.winbufnr(winnr)
    local element = {
      winnr = winnr,
      tabpage = tabpage,
      bufnr = bufnr,
      flag = flag,
      info = vim.fn.getbufinfo(bufnr)[1]
    }

    if max_tabpage < tabpage then
      max_tabpage = tabpage
    end
    if max_winnr < winnr then
      max_winnr = winnr
    end

    if opts.sort_lastused and flag == "%" then
      local idx = ((windows[1] ~= nil and windows[1].flag == "%") and 2 or 1)
      table.insert(windows, idx, element)
    else
      table.insert(windows, element)
    end
  end

  if not opts.tabpage_width then
    opts.tabpage_width = #tostring(max_tabpage)
  end

  if not opts.winnr_width then
    opts.winnr_width = #tostring(max_winnr)
  end

  pickers.new(
    opts,
    {
      prompt_title = "Windows",
      finder = finders.new_table {
        results = windows,
        entry_maker = opts.entry_maker or M.gen_from_window(opts)
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
      default_selection_index = default_selection_idx,
      attach_mappings = function(_)
        actions.select_default:replace(show_entry_window)
        return true
      end
    }
  ):find()
end

return require("telescope").register_extension {
  exports = {
    windows = M.windows
  }
}
