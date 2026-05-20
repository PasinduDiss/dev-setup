return {
	{
		"AckslD/swenv.nvim",
		dependencies = { "nvim-lua/plenary.nvim" }, -- Ensure plenary is installed
		config = function()
			require("swenv").setup({
				-- Customize if needed
				venvs_path = vim.fn.expand("~/Library/Caches/pypoetry/virtualenvs/"), -- Change to your venv path
				post_set_venv = function()
					vim.cmd("LspRestart") -- Restart LSP after switching venv
				end,
			})
			vim.keymap.set("n", "<leader>pv", function()
				require("swenv.api").pick_venv()
			end, { noremap = true, silent = true, desc = "Pick Python VirtualEnv" })
		end,
	},
}
