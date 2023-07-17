## Template.nvim

Quick insert tempalte

<img
src="https://user-images.githubusercontent.com/41671631/177514324-aad607cd-a25b-4c1e-ab81-13d780ec10f0.gif"
height="50%"
weight="50%"
/>

## Install

```lua
-- with lazy.nvim

{'glepnir/template.nvim', cmd = {'Template','TemProject'}, config = function()
    require('template').setup({
        -- config in there
    })
end}

-- lazy load you can use cmd or ft. if you are using cmd to lazyload when you edit the template file
-- you may see some diagnostics in template file. use ft to lazy load the diagnostic not display
-- when you edit the template file.
```

## Options

```lua
{
    temp_dir -- template directory
    author   -- your name
    email    -- email address
}
```

## Basic Usage

### Template Grammar

- `{{_date_}}`          insert current date

- `{{_cursor_}}`        set cursor here

- `{{_file_name_}}`      current file name

- `{{_author_}}`        author info

- `{{_email_}}`         email adrress

- `{{_variable_}}`      variable name

- `{{_upper_file_}}`     all-caps file name

- `{{_lua:vim.fn.expand(%:.:r)_}}`     set by lua script

### Define your template

You need to configure the setting variable `temp_dir`.
An example configuration: `temp.temp_dir = '~/.config/nvim/template`.
Create the directory at the location specified then proceed to add
template files.

As an example create the file `main_owner.go` in the `temp_dir`
directory you set (e.g. ~/.config/nvim/template/main_owner.go)

Nested folders are also supported (e.g. ~/.config/nvim/template/rust/http.rs)

```go
// Copyright {{_date_}} {{_author_}}. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package {{_file_name_}}

func main() {
 {{_cursor_}}
}

```

You can use lua inside the template with {{_lua:<somecode>}}.
For example
```markdown
---
created: {{_lua:os.date("%y/%m/%d %H/%M")_}}
---
```
above template generates below lines.
```markdown
---
created: 2022/12/29 21:52
---
```

- Work with existing file

if there has a file `main.go`, and open it input `Template <Tab>` . select the template `main_owner`

It will insert template to this file like

```go
// Copyright 2022-07-05 21:05:36 glephunter. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

func main() {
 | -- cursor in there
}

```

- Work with not exist file

use `Template test.go <TAB>`, it will create a file named `test.go` in current path and auto open
this file insert template.

- Work with not exist file and custom variable

A lua template file named `nvim_temp.lua`, content is

```lua
local api,fn = vim.api,vim.fn
local {{_variable_}}

{{_cursor_}}

return {{_variable_}}

```

Use `Template test.lua <TAB>` then it will auto fill template name `nvim_temp` if there 
is only one lua template file. If are any `_variable_`  items in the template file it will
prompt you for these values.

```lua
local api,fn = vim.api,vim.fn
local template

| -- cursor here

return template

```

- Use tpl file

Also you can use `*.tpl` as a template this extension can avoid trigger FileType event .like start a
lsp server by Filetype event.

a rule of `tpl` template is you must set `;; filetype` in first line like a rust template file
`http.tpl` and first line must be `;; rust` 


- Config a fancy keymap


```lua
vim.keymap.set('n', '<Leader>t', function()
    vim.fn.feedkeys(':Template ')
end, { remap = true})
```

- Find all templates

template.nvim can use `telescope`, but you need register template telescope extension to `telescope`

```lua
require("telescope").load_extension('find_template')
```

- Use Telescope to create template or insert template

```lua
-- This command will create a template file then show all templates
Telescope find_template name=templatename

-- When you select a template file it will insert this tempalte into current buffer
Telecope find_template type=insert

-- In both cases you can disable filtering templates by file type by passing `filter_ft=false`
Telecope find_template type=insert filter_ft=false
```

Then you can use `Telescope find_template` to check all templates

## Donate

[![](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/bobbyhub)

If you'd like to support my work financially, buy me a drink through [paypal](https://paypal.me/bobbyhub)

## Licenese MIT
