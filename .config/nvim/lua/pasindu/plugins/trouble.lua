return {
	"folke/trouble.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	opts = {
		focus = true,
		format = function(item, mode)
			local text = item.text or ""
			if type(text) ~= "string" then
				text = vim.inspect(text)
			end
			return text
		end,
	},
	cmd = "Trouble",
	keys = {
		{
			"<leader>xw",
			"<cmd>Trouble diagnostics toggle<CR>",
			desc = "Toggle workspace diagnostics",
		},
		{
			"<leader>xd",
			"<cmd>Trouble diagnostics toggle<CR>",
			desc = "Toggle document diagnostics",
		},
		{
			"<leader>xq",
			"<cmd>Trouble quickfix toggle<CR>",
			desc = "Toggle quickfix list",
		},
		{
			"<leader>xl",
			"<cmd>Trouble loclist toggle<CR>",
			desc = "Toggle location list",
		},
		{
			"<leader>xt",
			"<cmd>Trouble todo toggle<CR>",
			desc = "Toggle TODOs",
		},
	},
}
