## Template.nvim

Quickly insert templates into file.

<img
src="https://user-images.githubusercontent.com/41671631/177514324-aad607cd-a25b-4c1e-ab81-13d780ec10f0.gif"
height="50%"
weight="50%"
/>

## Install

```lua
-- with packer

use {'glepnir/template.nvim'}

```

## Options

```lua
local temp = require('template')

temp.temp_dir -- template directory
temp.author   -- your name
temp.email    -- email address

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

use `Template test.lua var=template <TAB>` then it will auto fill template name `nvim_temp` if there 
only has one lua template file.

```lua
local api,fn = vim.api,vim.fn
local template

| -- cursor here

return template

```

- Work with exist file and custom variable

use `Template var=template <TAB>`

- Config a fancy keymap

we can define a fancy keymap with the cmdline params like

```lua
vim.keymap.set('n', '<Leader>t', function()
  if vim.bo.filetype == 'lua' then
    return ':Template var='
  end

  if vim.bo.filetype == 'rust' then
    return '<cmd>Template main_owner<CR>'
  end
end, { remap = true})
```

this keymap will check the current filetype, if it's a lua filetype it will input the `Template var=`

in cmdline then just fill the variable name and template name, if filetype it's rust then it will

auto insert the content from `main_owner.rs` template.

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
