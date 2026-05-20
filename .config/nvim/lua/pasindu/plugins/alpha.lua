return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- Highlight settings
		vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#a3be8c", bg = "NONE" })
		dashboard.section.header.opts.hl = "AlphaHeader"

		-- Header art
		dashboard.section.header.val = {
			[[                                                                                  ]],
			[[                                   ██████                                         ]],
			[[	                             ████▒▒▒▒▒▒████                                     ]],
			[[                              ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                                  ]],
			[[                            ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                                ]],
			[[                          ██▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒                                  ]],
			[[                          ██▒▒▒▒▒▒  ▓▓▓▓  ▒▒▒▒  ▓▓▓▓                              ]],
			[[                          ██▒▒▒▒▒▒  ▒▒▓▓  ▒▒▒▒  ▒▒▓▓                              ]],
			[[                        ██▒▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒    ██                            ]],
			[[  ███╗   ██╗███████╗    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██    ██╗   ██╗██╗███╗   ███╗ ]],
			[[  ████╗  ██║██╔════╝    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒██    ██║   ██║██║████╗ ████║ ]],
			[[  ██╔██╗ ██║█████╗      ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒      ▒▒▒▒▒▒██    ██║   ██║██║██╔████╔██║ ]],
			[[  ██║╚██╗██║██╔══╝      ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒██    ╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
			[[  ██║ ╚████║███████╗    ██▒▒██▒▒▒▒▒▒██▒▒▒▒▒▒▒▒██▒▒▒▒██     ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
			[[  ╚═╝  ╚═══╝╚══════╝    ████  ██▒▒██  ██▒▒▒▒██  ██▒▒██      ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
			[[                        ██      ██      ████      ████                            ]],
		}

		-- Dashboard menu
		dashboard.section.buttons.val = {
			dashboard.button("p", "📙  List Projects", "<cmd>Telescope project<CR>"),
			dashboard.button("e", "📄  New File", "<cmd>ene<CR>"),
			dashboard.button("ee", "📂  Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("ff", "🔍  Find File", "<cmd>Telescope find_files<CR>"),
			dashboard.button("fs", "🔬  Find Word", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("wr", "🔄  Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
			dashboard.button("q", "🚪  Quit NVIM", "<cmd>qa<CR>"),
		}

		-- Save original guicursor so we can restore it
		local saved_guicursor = vim.o.guicursor

		-- Hide cursor when Alpha is ready
		vim.api.nvim_create_autocmd("User", {
			pattern = "AlphaReady",
			callback = function()
				-- Hide actual cursor
				vim.o.guicursor = ""

				-- Hide cursor highlight
				vim.api.nvim_win_set_option(0, "winhighlight", "Normal:Normal,Cursor:AlphaCursor")
				vim.cmd("highlight AlphaCursor blend=100")
			end,
		})

		-- Restore cursor when leaving Alpha buffer
		vim.api.nvim_create_autocmd("BufUnload", {
			pattern = "*",
			callback = function()
				if vim.bo.filetype == "alpha" then
					-- Restore cursor shape and highlight
					vim.o.guicursor = saved_guicursor
					vim.api.nvim_win_set_option(0, "winhighlight", "")
					vim.cmd("highlight clear AlphaCursor")
				end
			end,
		})

		-- Disable folding
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

		-- Activate Alpha
		alpha.setup(dashboard.opts)
	end,
}
