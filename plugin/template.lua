if vim.g.load_template then
  return
end

vim.g.load_template = true

local api = vim.api

api.nvim_create_user_command('Template', function(args)
  require('template'):generate_template(args.fargs)
end, {
  nargs = '+',
  complete = function(arg, line)
    local temp = require('template')
    if not temp.temp_dir then
      vim.notify('[template.nvim] please config the temp_dir variable')
      return {}
    end

    local list = temp.get_temp_list()
    local function match_item(ft)
      return vim.tbl_map(function(s)
        if string.match(s, '^' .. arg) then
          return s
        end
      end, list[ft])
    end

    local ft = api.nvim_buf_get_option(0, 'filetype')
    if list[ft] then
      return match_item(ft)
    end

    local args = vim.split(line, '%s+', { trimempty = true })
    if #args == 1 and not list[ft] then
      return
    end

    if #args >= 2 and args[2]:find('%.%w+$') then
      ft = vim.filetype.match({ filename = args[2] })
    end

    if ft then
      return match_item(ft)
    end
  end,
})
