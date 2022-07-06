## Template.nvim

Quickly insert templates into file.

## Install

```lua
-- with packer

use {'glepnir/template.nvim'}

```

## Options

```lua
local temp = require('tempalte')

temp.temp_dir -- template directory
temp.author   -- your name
temp.email    -- email address

```

## Basic Usage

### Template Grammer

- `{{_date_}}`          insert current date

- `{{_cursor_}}`        set cursor here

- `{{_file_name}}`      current file name

- `{{_author_}}`        author info

- `{{_email_}}`         email adrress

- `{{_variable_}}`      variable name

### Define your tempalte

Define a template for a go file. template named `main_owner.go` in `temp.temp_dir` .in my local config it
to `~/.config/nvim/template`

```go
// Copyright {{_date_}} {{_author_}}. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package {{_file_name}}

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
 | -- cusror in there
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

use `Template var=tempalte <TAB>`

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
