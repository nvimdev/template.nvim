local api = vim.api
local temp = require('template')
local temp_group = api.nvim_create_augroup('Template', { clear = true })

api.nvim_create_user_command('Template', function(args)
  require('template'):generate_template(args.args)
end, {
  nargs = '*',
  complete = function(arg, line)
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

    return vim.tbl_filter(function(s)
      return string.match(s, '^' .. arg)
    end, list[ft])
  end,
})

if vim.fn.has('nvim-0.8') == 1 then
  api.nvim_create_autocmd('LspAttach', {
    group = temp_group,
    callback = function()
      if vim.bo.filetype ~= 'lua' then
        return
      end

      if temp.check_path_in() then
        vim.diagnostic.disable()
      end
    end,
  })
end
