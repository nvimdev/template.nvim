local temp = {}
local uv, api, fn = vim.loop, vim.api, vim.fn
local is_windows = uv.os_uname().sysname == 'Windows'
local sep = is_windows and '\\' or '/'

temp.temp_dir = ''
temp.author = ''
temp.email = ''

function temp.get_temp_list()
  local all_temps = vim.split(fn.globpath(temp.temp_dir, '*'), '\n')

  local list = {}
  for _, v in pairs(all_temps) do
    local tbl = vim.split(v, sep, { trimempty = true })
    local ft = vim.filetype.match({ filename = tbl[#tbl] })

    if list[ft] == nil then
      list[ft] = {}
    end
    local tp_name = tbl[#tbl]:match('(.+)%.%w+')
    table.insert(list[ft], tp_name)
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
    return ctx.line:gsub(expr[6], ctx.var)
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

function temp:generate_template(args)
  local data = parse_args(args)

  if data.file then
    create_and_load(data.file)
  end

  local current_buf = api.nvim_get_current_buf()

  local ext = fn.expand('%:e')
  local tpl = vim.fs.normalize(temp.temp_dir) .. sep .. data.tp_name .. '.' .. ext

  local lines = {}
  local cursor_pos = {}
  local lnum = 0

  local ctx = { var = data.var, line = '' }

  for line in io.lines(tpl) do
    lnum = lnum + 1
    for idx, key in pairs(expr) do
      if line:find(key) then
        ctx.line = line
        line = expand_expr[expr[idx]](ctx)

        if idx == 2 then
          cursor_pos = { lnum, 2 }
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
end

function temp.in_template(buf)
  local fname = api.nvim_buf_get_name(buf)
  if #fname == 0 then
    return false
  end
  local list = temp.get_temp_list()
  if not list[vim.bo[buf].filetype] then
    return false
  end

  if fname:find(temp.temp_dir) then
    return true
  end

  local fname_parts = vim.split(fname, sep, { trimempty = true })
  local tp_name = fname_parts[#fname_parts]:match('(.+)%.%w+')

  if tp_name and vim.tbl_contains(list[vim.bo[buf].filetype], tp_name) then
    return true
  end

  return false
end

return temp
