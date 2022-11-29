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
