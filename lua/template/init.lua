local temp = {}
local uv, api, fn, fs = vim.loop, vim.api, vim.fn, vim.fs
local sep = uv.os_uname().sysname == 'Windows_NT' and '\\' or '/'
local utils = require("template.utils")

function temp.get_temp_list()
  temp.temp_dir = fs.normalize(temp.temp_dir)
  local all_temps = {}
  local req = uv.fs_scandir(temp.temp_dir)
  if not req then
    vim.notify('[template.nvim] something wrong in get_temp_list callback')
    return
  end

  local function iter()
    return uv.fs_scandir_next(req)
  end

  for name, type in iter do
    if type == 'file' then
      table.insert(all_temps, name)
    end
  end

  local list = {}
  for _, v in pairs(all_temps or {}) do
    local ft = vim.filetype.match({ filename = v })
    if ft then
      list[ft] = {}
      table.insert(list[ft], v)
    end
  end

  return list
end

local expr = {
  '{{_date_}}',
  '{{_cursor_}}',
  '{{_file_name_}}',
  '{{_author_}}',
  '{{_email_}}',
  '{{_variable_}}',
  '{{_upper_file_}}',
}

--@private
local expand_expr = {
  [expr[1]] = function(ctx)
    local date = os.date('%Y-%m-%d %H:%M:%S')
    return ctx.line:gsub(expr[1], date)
  end,
  [expr[2]] = function(ctx)
    return ctx.line:gsub(expr[2], '')
  end,
  [expr[3]] = function(ctx)
    local file_name = fn.expand('%:t:r')
    return ctx.line:gsub(expr[3], file_name)
  end,
  [expr[4]] = function(ctx)
    return ctx.line:gsub(expr[4], temp.author)
  end,
  [expr[5]] = function(ctx)
    return ctx.line:gsub(expr[5], temp.email)
  end,
  [expr[6]] = function(ctx)
    return ctx.var and ctx.line:gsub(expr[6], ctx.var) or utils.input("var: ")
  end,
  [expr[7]] = function(ctx)
    local file_name = string.upper(fn.expand('%:t:r'))
    return ctx.line:gsub(expr[7], file_name)
  end,
}

--@private
local function create_and_load(file)
  local current_path = fn.getcwd()
  file = current_path .. sep .. file
  local ok, fd = pcall(uv.fs_open, file, 'w', 420)
  if not ok then
    vim.notify("Couldn't create file " .. file)
    return
  end
  uv.fs_close(fd)

  vim.cmd(':e ' .. file)
end

local function parse_args(args)
  local data = {}

  for _, v in pairs(args) do
    if v:find('^var') then
      data.var = vim.split(v, '=')[2]
    end
    if v:find('%.%w+') then
      data.file = v
    end
    data.tp_name = v
  end

  return data
end

local function async_read(path, callback)
  uv.fs_open(path, 'r', 438, function(err, fd)
    assert(not err, err)
    uv.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      uv.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        uv.fs_close(fd, function(err)
          assert(not err, err)
          return callback(data)
        end)
      end)
    end)
  end)
end

function temp:generate_template(args)
  local data = parse_args(args)

  if data.file then
    create_and_load(data.file)
  end

  local current_buf = api.nvim_get_current_buf()

  local ext = fn.expand('%:e')
  local tpl = fs.normalize(temp.temp_dir) .. sep .. data.tp_name .. '.' .. ext

  local lines = {}

  local ctx = { var = data.var, line = '' }

  async_read(
    tpl,
    vim.schedule_wrap(function(data)
      local cursor_pos = {}
      local tbl = vim.split(data, '\n')
      for i, line in pairs(tbl) do
        for idx, key in pairs(expr) do
          if line:find(key) then
            ctx.line = line
            line = expand_expr[expr[idx]](ctx)
            if not line then
              return
            end

            if idx == 2 then
              cursor_pos = { i, 2 }
            end
          end
        end
        table.insert(lines, line)
      end

      if fn.line2byte('$') ~= -1 then
        local content = api.nvim_buf_get_lines(current_buf, 0, -1, false)
        for _, line in pairs(content) do
          table.insert(lines, line)
        end
      end

      api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)

      if next(cursor_pos) ~= nil then
        api.nvim_win_set_cursor(0, cursor_pos)
        vim.cmd('startinsert!')
      end
    end)
  )
end

function temp.in_template(buf)
  local list = temp.get_temp_list()
  if not list then
    return false
  end

  if not list[vim.bo[buf].filetype] then
    return false
  end

  local tail = fn.expand('%:t')

  if vim.tbl_contains(list[vim.bo[buf].filetype], tail) then
    return true
  end

  return false
end

function temp.setup(config)
  vim.validate({
    config = { config, 't' },
  })

  if not config.temp_dir then
    vim.notify('[template.nvim] please config the temp_dir variable')
    return
  end

  temp.temp_dir = config.temp_dir

  temp.author = config.author and config.author or ''
  temp.email = config.email and config.email or ''

  local ft = vim.tbl_keys(temp.get_temp_list() or {})

  if #ft == 0 then
    vim.notify('[template.nvim] does not get the filetype in template dir')
    return
  end

  api.nvim_create_autocmd('FileType', {
    pattern = ft,
    group = api.nvim_create_augroup('Template', { clear = true }),
    callback = function(opt)
      if temp.in_template(opt.buf) then
        vim.diagnostic.disable(opt.buf)
      end
    end,
  })
end

return temp
