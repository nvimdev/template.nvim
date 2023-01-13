local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local temp_list = function()
  local temp = require('template')
  return vim.split(vim.fn.globpath(temp.temp_dir, '*'), '\n')
end

local find_template = function(opts)
  local cur_buf = vim.api.nvim_get_current_buf()
  opts = opts or {}
  if opts.name then
    local dir = require('template').temp_dir
    local path = vim.loop.os_uname().version:match('Windows') and '\\' or '/'
    local file = dir .. path .. opts.name
    if vim.fn.filereadable(file) == 0 then
      local ok, fd = pcall(vim.loop.fs_open, file, 'w', 420)
      if not ok then
        vim.notify("Couldn't create file " .. file)
        return
      end
      vim.loop.fs_close(fd)
    end
  end

  local results = temp_list()

  local tbl = {
    prompt_title = 'find in templates',
    results_title = 'templates',
    finder = finders.new_table({
      results = results,
      entry_maker = make_entry.gen_from_file(opts),
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts),
  }

  if opts.type then
    tbl.attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local tmp_name = selection[1]
        local lines = {}
        local fd = io.open(tmp_name, 'r')
        if not fd then
          return
        end
        for line in fd:lines() do
          table.insert(lines, line)
        end
        fd:close()

        local count = vim.api.nvim_buf_line_count(cur_buf)
        vim.api.nvim_buf_set_lines(cur_buf, count, count, false, lines)
      end)
      return true
    end
  end

  pickers.new(opts, tbl):find()
end

return telescope.register_extension({ exports = { find_template = find_template } })
