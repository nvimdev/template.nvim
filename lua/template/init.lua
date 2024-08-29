local temp = {}
local uv, api, fn, fs = vim.loop, vim.api, vim.fn, vim.fs
local sep = uv.os_uname().sysname == 'Windows_NT' and '\\' or '/'

local cursor_pattern = '{{_cursor_}}'
local renderer = {
  expressions = {},
  expression_replacer_map = {},
}

---@param expr string
---@param replacer function(match: string): string
renderer.register = function(expr, replacer)
  if renderer.expression_replacer_map[expr] then
    vim.notify('The expression ' .. expr .. ' is registered already. Will not add the replacer.', vim.log.levels.ERROR)
    return
  end
  table.insert(renderer.expressions, expr)
  renderer.expression_replacer_map[expr] = replacer
end

renderer.register_builtins = function()
  renderer.register('{{_date_}}', function(_)
    return os.date('%Y-%m-%d %H:%M:%S')
  end)
  renderer.register(cursor_pattern, function(_)
    return ''
  end)
  renderer.register('{{_file_name_}}', function(_)
    return fn.expand('%:t:r')
  end)
  renderer.register('{{_author_}}', function(_)
    return temp.author
  end)
  renderer.register('{{_email_}}', function(_)
    return temp.email
  end)
  renderer.register('{{_variable_}}', function(_)
    return vim.fn.input('Variable name: ', '')
  end)
  renderer.register('{{_upper_file_}}', function(_)
    return string.upper(fn.expand('%:t:r'))
  end)
  renderer.register('{{_lua:(.-)_}}', function(matched_expression)
    return load('return ' .. matched_expression)()
  end)
  renderer.register('{{_tomorrow_}}', function()
    local t = os.date('*t')
    t.day = t.day + 1
    ---@diagnostic disable-next-line: param-type-mismatch
    return os.date('%c', os.time(t))
  end)
  renderer.register('{{_camel_file_}}', function(_)
    local file_name = fn.expand('%:t:r')
    local camel_case_file_name = ''
    local up_next = true
    for i = 1, #file_name do
      local char = file_name:sub(i, i)
      if char == '_' then
        up_next = true
      elseif up_next then
        camel_case_file_name = camel_case_file_name .. string.upper(char)
        up_next = false
      else
        camel_case_file_name = camel_case_file_name .. char
      end
    end
    return camel_case_file_name
  end)
end

renderer.render_line = function(line)
  local rendered = vim.deepcopy(line)
  for _, expr in ipairs(renderer.expressions) do
    if line:find(expr) then
      while rendered:match(expr) do
        local replacement = renderer.expression_replacer_map[expr](rendered:match(expr))
        rendered = rendered:gsub(expr, replacement, 1)
      end
    end
  end
  return rendered
end

function Get_file_extention(url)
  return url:match("^.+%.(.+)$")
end

function temp.get_temp_list()
  local current_buf = api.nvim_get_current_buf()
  temp.temp_dir = fs.normalize(temp.temp_dir)
  local res = {}

  local result = vim.fs.find(function(name)
    return name:match('.*')
  end, { type = 'file', path = temp.temp_dir, limit = math.huge })

  local link = vim.fs.find(function(name)
    return name:match('.*')
  end, { type = 'link', path = temp.temp_dir, limit = math.huge })

  result = vim.list_extend(result, link)

  for _, name in ipairs(result) do
    local extention = Get_file_extention(name)
    local ft = vim.bo[current_buf].filetype == extention

    if not ft and extention == "tpl" then
      local first_row = vim.fn.readfile(name, '', 1)[1]
      extention = vim.split(first_row, '%s')[2]
      print(extention)
      ft = true
    end

    if ft then
      if not res[extention] then
        res[extention] = {}
      end
      res[extention][#res[extention]+1] = name
    -- else
      -- vim.notify('[Template.nvim] Could not find the filetype of template file ' .. name, vim.log.levels.INFO)
    end
  end

  return res
end

local function expand_expressions(line)
  local cursor

  if line:find(cursor_pattern) then
    cursor = true
  end

  line = renderer.render_line(line)

  return line, cursor
end

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
    ---@diagnostic disable-next-line: redefined-local
    uv.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      ---@diagnostic disable-next-line: redefined-local
      uv.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        ---@diagnostic disable-next-line: redefined-local
        uv.fs_close(fd, function(err)
          assert(not err, err)
          return callback(data)
        end)
      end)
    end)
  end)
end

local function get_tpl(buf, name)
  local list = temp.get_temp_list()
  if not list[vim.bo[buf].filetype] then
    return
  end

  for _, v in ipairs(list[vim.bo[buf].filetype]) do
    if v:find(name) then
      return v
    end
  end
end

function temp:generate_template(args)
  local data = parse_args(args)

  if data.file then
    create_and_load(data.file)
  end

  local current_buf = api.nvim_get_current_buf()

  local tpl = get_tpl(current_buf, data.tp_name)
  if not tpl then
    return
  end

  local lines = {}

  async_read(
    tpl,
    ---@diagnostic disable-next-line: redefined-local
    vim.schedule_wrap(function(data)
      local cursor_pos = {}
      data = data:gsub('\r\n?', '\n')
      local tbl = vim.split(data, '\n')

      local skip_lines = 0

      for i, v in ipairs(tbl) do
        if i == 1 then
          local line_data = vim.split(v, '%s')
          if #line_data == 2 and ';;' == line_data[1] then
            skip_lines = skip_lines + 1
            goto continue
          end
        end
        local line, cursor = expand_expressions(v)
        lines[#lines + 1] = line
        if cursor then
          cursor_pos = { i - skip_lines, 2 }
        end
        ::continue::
      end

      local cur_line = api.nvim_win_get_cursor(0)[1]
      local start = cur_line
      if cur_line == 1 and #api.nvim_get_current_line() == 0 then
        start = cur_line - 1
      end
      api.nvim_buf_set_lines(current_buf, start, cur_line, false, lines)
      if cursor_pos[1] ~= nil then
        cursor_pos[1] = start ~= 0 and cur_line + cursor_pos[1] or cursor_pos[1]

        if next(cursor_pos) ~= nil then
          api.nvim_win_set_cursor(0, cursor_pos)
          vim.cmd('startinsert!')
        end
      end
    end)
  )
end

function temp.in_template(buf)
  local list = temp.get_temp_list()
  if vim.tbl_isempty(list) or not list[vim.bo[buf].filetype] then
    return false
  end
  local bufname = api.nvim_buf_get_name(buf)

  if vim.tbl_contains(list[vim.bo[buf].filetype], bufname) then
    return true
  end

  return false
end

temp.register = renderer.register

function temp.setup(config)
  renderer.register_builtins()
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

  local fts = vim.tbl_keys(temp.get_temp_list())

  if #fts == 0 then
    vim.notify('[template.nvim] does not get the filetype in template dir')
    return
  end

  api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile' }, {
    pattern = temp.temp_dir .. '/*',
    group = api.nvim_create_augroup('Template', { clear = false }),
    callback = function(opt)
      if vim.bo[opt.buf].filetype == 'smarty' then
        local fname = api.nvim_buf_get_name(opt.buf)
        local row = vim.fn.readfile(fname, '', 1)[1]
        local lang = vim.split(row, '%s')[2]
        vim.treesitter.start(opt.buf, lang)
        api.nvim_buf_add_highlight(opt.buf, 0, 'Comment', 0, 0, -1)
        return
      end

      if temp.in_template(opt.buf) then
        vim.diagnostic.disable(opt.buf)
      end
    end,
  })
end

return temp
