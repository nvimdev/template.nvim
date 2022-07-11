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

    if #cmd > 1 and cmd[1]:find('%.%w+$') then
      ft = cmd[1]:match('[^.]+$')
    end

    local list = temp.get_temp_list()
    return vim.tbl_filter(function(s)
      return string.match(s, '^' .. arg)
    end, list[ft])
  end,
})

api.nvim_create_autocmd('LspAttach', {
  group = temp_group,
  callback = function()
    if vim.bo.filetype ~= 'lua' then
      return
    end

    if temp.check_path_in() then
      vim.lsp.stop_client(vim.lsp.get_active_clients())
    end
  end,
})
