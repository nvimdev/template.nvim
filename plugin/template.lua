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
            vim.notify('[Templates] please config the temp_dir variable')
            return {}
        end

        local list = temp.get_temp_list()

        local function match_item(ft)
            return vim.tbl_map(function(s)
                s = vim.fn.fnamemodify(s, ':t:r')
                if arg and string.match(s, '^' .. arg) then
                    return s
                end
                return s
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

api.nvim_create_user_command('TemplateCreate', function(args)
    local temp = require('template')
    local temp_dir = temp.temp_dir
    if not temp_dir then
        vim.notify('[Templates] please config the temp_dir variable')
        return
    end
    local file = temp:parse_args(args).file
    if not file then
        vim.notify('[Templates] please provide a file')
        return
    end
    local temp_loc = temp_dir .. '/' .. file
    vim.notify('[Templates] created new template at ' .. temp_loc)
    vim.cmd(':edit ' .. temp_loc)
end, {
    nargs = 1,
})
