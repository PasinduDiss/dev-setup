return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open diff view" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
		{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
	},
	opts = {
		enhanced_diff_hl = true,
		view = {
			default = {
				layout = "diff2_horizontal",
			},
			merge_tool = {
				layout = "diff3_horizontal",
			},
			file_history = {
				layout = "diff2_horizontal",
			},
		},
		file_panel = {
			win_config = {
				position = "left",
				width = 35,
			},
		},
		keymaps = {
			view = {
				["q"] = "<cmd>DiffviewClose<cr>",
			},
			file_panel = {
				["q"] = "<cmd>DiffviewClose<cr>",
			},
			file_history_panel = {
				["q"] = "<cmd>DiffviewClose<cr>",
			},
		},
	},
}
