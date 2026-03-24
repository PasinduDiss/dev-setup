return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
		"nvim-telescope/telescope-project.nvim",
		"AckslD/swenv.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local transform_mod = require("telescope.actions.mt").transform_mod

		local trouble = require("trouble")
		local trouble_telescope = require("trouble.sources.telescope")

		-- or create your custom action
		local custom_actions = transform_mod({
			open_trouble_qflist = function(prompt_bufnr)
				trouble.toggle("quickfix")
			end,
		})

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_to_qflist,
						["<C-t>"] = trouble_telescope.open,
						["<C-a>"] = actions.toggle_all,
					},
				},
			},
			extensions = {
				project = {
					base_dirs = { "~/code/zendesk/", "~/.config/" },
					hidden_files = false,
					theme = "dropdown",
					on_project_selected = function(prompt_bufnr)
						local actions_state = require("telescope.actions.state")
						local actions = require("telescope.actions")
						local selected = actions_state.get_selected_entry()
						actions.close(prompt_bufnr)
						if selected and selected.value then
							local path = vim.fn.expand(selected.value)
							vim.api.nvim_set_current_dir(path)
							require("telescope.builtin").find_files()
						end
					end,
				},
			},
      pickers = {
        find_files = {
          hidden = true,
        },
        live_grep = {
          additional_args = { "--hidden" },
        },
      },
		})

		telescope.load_extension("fzf")
		telescope.load_extension("project")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>fp", "<cmd>Telescope project<cr>", { desc = "List projects" })
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
		keymap.set("n", "<leader>fu", "<cmd>Telescope buffers<cr>", { desc = "Buffer slector (for navigating Tabs)" })
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
	end,
}
