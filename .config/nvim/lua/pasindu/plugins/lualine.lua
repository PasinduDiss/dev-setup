return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = "everforest", -- Use the Everforest theme
				section_separators = { left = "", right = "" }, -- Slanting to the right
				component_separators = { left = "", right = "" }, -- Slanted inner separators
				globalstatus = true, -- Enable global statusline
			},
			tabline = {
				lualine_a = { "buffers" }, -- Buffers on the left
				lualine_b = {}, -- Empty for spacing
				lualine_c = { "filename" }, -- File name in the center
				lualine_x = {}, -- Empty for spacing
				lualine_y = { "tabs" }, -- Tabs section near the right
				lualine_z = {
					function()
						return "🍄🍄🍄"
					end,
				},
			},
			sections = {
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
					},
					{ "encoding" },
					{ "filetype" },
					{ "fileformat" },
				},
			},
		})
	end,
}
