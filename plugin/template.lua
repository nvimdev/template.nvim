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
    local cmd = vim.split(line, '%s+')
    table.remove(cmd, 1)
    local ft = vim.bo.filetype
    if ft == '' then
      vim.notify('current buffer does not have filetype set')
      return {}
    end

    if #cmd > 1 and cmd[1]:find('%.%w+$') then
      ft = cmd[1]:match('[^.]+$')
    end

    local list = temp.get_temp_list()

    if not list then
      vim.notify('get all templates list failed')
      return {}
    end

    return vim.tbl_map(function(s)
      local ext = vim.fn.expand('%:e')
      if string.match(s, '^' .. arg) then
        s = s:gsub('%.' .. ext, '')
        return s
      end
    end, list[ft])
  end,
})
