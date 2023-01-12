local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values

local temp_list = function()
  local temp = require('template')
  return vim.split(vim.fn.globpath(temp.temp_dir, '*'), '\n')
end

local find_template = function(opts)
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

  pickers
    .new(opts, {
      prompt_title = 'find in templates',
      results_title = 'templates',
      finder = finders.new_table({
        results = results,
        entry_maker = make_entry.gen_from_file(opts),
      }),
      previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
    })
    :find()
end

return telescope.register_extension({ exports = { find_template = find_template } })
