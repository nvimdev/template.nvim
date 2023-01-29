local api, fn, uv = vim.api, vim.fn, vim.loop
local pj = {}

function pj:complete_list()
  local res = {}
  for _, item in pairs(self.conf) do
    if item['lang'] then
      vim.tbl_map(function(k)
        if not vim.tbl_contains(res, k) then
          table.insert(res, k)
        end
      end, vim.tbl_keys(item['lang']))
    end
  end

  return res
end

local function path_join(...)
  local path_sep = uv.os_uname().sysname == 'WindowsNT' and '\\' or '/'
  return table.concat({ ... }, path_sep)
end

function pj:complete_project(langs)
  local function generation(cwd, tbl)
    if vim.tbl_islist(tbl) then
      for _, v in pairs(tbl) do
        local path = path_join(cwd, v)
        if fn.filereadable(path) == 0 then
          local f = io.open(path, 'w')
          if not f then
            vim.notify('template.nvim create ' .. path .. ' failed')
            return
          end
          f:close()
        end
      end
      return
    end

    for name, item in pairs(tbl) do
      if name == 'default' then
        generation(cwd, item)
      else
        local dir = path_join(cwd, name)
        if fn.isdirectory(dir) == 0 then
          fn.mkdir(dir, 'p')
          generation(dir, item)
        end
      end
    end
  end

  local cur_dir = uv.cwd()
  for _, items in pairs(self.conf) do
    for name, data in pairs(items) do
      if name == 'lang' then
        vim.tbl_map(function(k)
          if items['lang'][k] then
            generation(cur_dir, items['lang'][k])
          end
        end, langs)
      else
        generation(cur_dir, data)
      end
    end
  end
end

function pj:register_command(conf)
  self.conf = conf
  api.nvim_create_user_command('TemProject', function(args)
    self:complete_project(args.fargs)
  end, {
    nargs = '+',
    complete = function()
      return self:complete_list()
    end,
  })
end

return pj
