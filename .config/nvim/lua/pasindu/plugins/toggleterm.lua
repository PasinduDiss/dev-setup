return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<C-\\>]], -- This is the key mapping for toggling the terminal
			hide_numbers = true, -- Hide number column in terminal buffer
			shade_filetypes = {},
			start_in_insert = true,
			insert_mappings = true, -- Allow mappings in insert mode
			terminal_mappings = true, -- Use mappings in terminal mode
			persist_size = true,
			direction = "float", -- Options: 'vertical' | 'horizontal' | 'tab' | 'float'
			float_opts = {
				border = "curved", -- Border style: 'single', 'double', 'shadow', 'curved'
				winblend = 0, -- Transparency level (0 = opaque, 100 = fully transparent)
				highlights = {
					border = "Normal", -- Highlight group for the border
					background = "TermNormal", -- Highlight group for the background
				},
			},
			shade_terminals = false, -- Shades the background of the terminal
			shading_factor = 2, -- Degree of shading for the terminal
			close_on_exit = true, -- Automatically close the terminal when the process exits
			shell = vim.o.shell, -- Use the default shell
		})

		local keymap = vim.keymap

		keymap.set("n", "<C-;>", "<Cmd>ToggleTerm<CR>", {
			noremap = true,
			silent = true,
			desc = "Toggle terminal (open/close)",
		})

		-- Toggle terminal with <C-\> in terminal mode
		keymap.set("t", "<C-;>", "<Cmd>ToggleTerm<CR>", {
			noremap = true,
			silent = true,
			desc = "Toggle terminal from inside the terminal",
		})
	end,
}
