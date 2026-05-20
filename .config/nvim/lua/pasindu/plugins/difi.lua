return {
	"oug-t/difi.nvim",
	cmd = { "Difi", "DifiHealth" },
	keys = {
		{ "<leader>dft", "<cmd>Difi<cr>", desc = "Toggle Difi (vs HEAD)" },
		{ "<leader>dfm", "<cmd>Difi main<cr>", desc = "Difi vs main" },
		{ "<leader>dfh", "<cmd>DifiHealth<cr>", desc = "Difi health check" },
	},
	opts = {},
}
