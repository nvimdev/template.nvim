local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local temp_list = function(opts)
  local temp = require('template')
  local list = vim.split(vim.fn.globpath(temp.temp_dir, '*'), '\n')
  local res = {}
  for _, fname in pairs(list or {}) do
    if opts.filter_ft then
      local ft = vim.filetype.match({ filename = fname })
      if ft and ft == vim.bo.filetype then
        res[#res + 1] = fname
      end
    else
      res[#res + 1] = fname
    end
  end
  return res
end

local find_template = function(opts)
  opts = opts or {}
  if opts.name then
    local dir = require('template').temp_dir
    local path = vim.loop.os_uname().sysname == 'Windows_NT' and '\\' or '/'
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

  -- by default is set for type=insert
  -- unless is explicitly set by the filter_ft option which takes precedence
  local filter_ft = (opts.type == 'insert')
  if opts.filter_ft ~= nil then
    filter_ft = opts.filter_ft
  end

  local results = temp_list({ filter_ft = filter_ft })

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
        local tmp_name = vim.fn.fnamemodify(selection[1], ':t')
        tmp_name = vim.split(tmp_name, '%.', { trimempty = true })[1]

        vim.cmd('Template ' .. tmp_name)
      end)
      return true
    end
  end

  pickers.new(opts, tbl):find()
end

return telescope.register_extension({ exports = { find_template = find_template } })
