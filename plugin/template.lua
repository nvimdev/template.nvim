local api = vim.api
local temp = require('template')

api.nvim_create_user_command('Template',function(args)
  require('template'):generate_template(args.args)
end,{
  nargs = '*',
  complete = function(arg,line)
    local cmd = vim.split(line,'%s+')

    local ft = string.len(cmd[2]) ~= 0 and cmd[2]:match('[^.]+$') or vim.bo.filetype

    local list = temp.get_temp_list()
    return vim.tbl_filter(function (s)
            return string.match(s, "^" .. arg)
          end,list[ft])
  end
})
