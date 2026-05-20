return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 20,
			hide_numbers = true,
			shade_filetypes = {},
			start_in_insert = true,
			insert_mappings = true,
			terminal_mappings = true,
			persist_size = true,
			direction = "float",
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "TermNormal",
				},
			},
			shade_terminals = false,
			shading_factor = 2,
			close_on_exit = true,
			shell = vim.o.shell,
		})

		local Terminal = require("toggleterm.terminal").Terminal

		local tmux_term = Terminal:new({
			-- Create a named tmux session with zsh/lazygit/btop windows on first open;
			-- subsequent opens re-attach to the existing session.
			cmd = [[zsh -c 'SESSION=nvim-term; if ! tmux has-session -t "$SESSION" 2>/dev/null; then tmux new-session -d -s "$SESSION" -n zsh && tmux new-window -t "$SESSION" -n lazygit lazygit && tmux new-window -t "$SESSION" -n btop btop && tmux select-window -t "$SESSION:zsh"; fi; exec tmux attach-session -t "$SESSION"']],
			direction = "float",
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "TermNormal",
				},
			},
			close_on_exit = true,
			on_open = function(_)
				vim.cmd("startinsert!")
			end,
		})

		local keymap = vim.keymap

		keymap.set({ "n", "t" }, "<C-;>", function()
			tmux_term:toggle()
		end, {
			noremap = true,
			silent = true,
			desc = "Toggle tmux terminal (zsh / lazygit / btop)",
		})
	end,
}
