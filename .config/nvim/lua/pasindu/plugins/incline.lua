return {
	"b0o/incline.nvim",
	dependencies = { "sainnhe/everforest" }, -- Ensure Everforest is installed
	event = "BufReadPre",
	priority = 1200,
	config = function()
		-- Define Everforest colors manually
		local colors = {
			bg1 = "#323d43", -- Background for non-active buffers
			bg3 = "#3a454a", -- Background for active buffers
			aqua = "#7fbbb3", -- Aqua text color
			grey1 = "#868d80", -- Grey for non-active text
		}

		require("incline").setup({
			highlight = {
				groups = {
					InclineNormal = { guibg = colors.bg3, guifg = colors.aqua },
					InclineNormalNC = { guibg = colors.bg1, guifg = colors.grey1 },
				},
			},
			window = { margin = { vertical = 0, horizontal = 1 } },
			hide = {
				cursorline = true,
			},
			render = function(props)
				-- Get the filename
				local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
				if vim.bo[props.buf].modified then
					filename = "[+] " .. filename
				end

				-- Get the file icon and its associated color
				local icon, color = require("nvim-web-devicons").get_icon_color(filename)
				return { { icon, guifg = color }, { " " }, { filename } }
			end,
		})
	end,
}
