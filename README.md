## Template.nvim

Async insert templates into file.

<img
src="https://user-images.githubusercontent.com/41671631/177514324-aad607cd-a25b-4c1e-ab81-13d780ec10f0.gif"
height="50%"
weight="50%"
/>

## Install

```lua
-- with lazy.nvim

{'glepnir/template.nvim', cmd = 'Template', config = function()
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

You need config the `temp_dir` first like `temp.temp_dir = '~/.config/nvim/template` then create the

a template named `main_owner.go` for go language in the `temp_dir`

```go
// Copyright {{_date_}} {{_author_}}. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package {{_file_name_}}

func main() {
 {{_cursor_}}
}

```

- Work with exist file

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

a lua template file named `nvim_temp.lua`, content is

```lua
local api,fn = vim.api,vim.fn
local {{_variable_}}

{{_cursor_}}

return {{_variable_}}

```

use `Template test.lua <TAB>` then it will auto fill template name `nvim_temp` if there 
only has one lua template file. if there has `_variable_` set then it will pop up an input
then input your variable name.

```lua
local api,fn = vim.api,vim.fn
local template

| -- cursor here

return template

```

- Config a fancy keymap


```lua
vim.keymap.set('n', '<Leader>t', function()
    return ':Template '
end, { remap = true})
```


- Find all templates

template.nvim use `telescope`. so you need register template telescope extension to `telescope`

```lua

require("telescope").load_extension('find_template')

```

Then you can use `Telescope find_template` to check all templates

## Donate

[![](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/bobbyhub)

If you'd like to support my work financially, buy me a drink through [paypal](https://paypal.me/bobbyhub)

## Licenese MIT
