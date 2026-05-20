vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentations
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from the current line when starting a new one

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when search
opt.smartcase = true -- if you include mixed case in your search, assumes you want case sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorschems to work
-- (have to use a true color terminal)
opt.termguicolors = true
opt.background = "dark" -- color schemes that has a light and dark version will be constrained to use dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- split vertical widnow to the right
opt.splitbelow = true -- split horizontal widow to the bottom

-- undo after close
opt.undofile = true
