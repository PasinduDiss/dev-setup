return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		{ "mfussenegger/nvim-jdtls" }, -- Java handled outside lspconfig
	},
	config = function()
		-- Native Neovim 0.11+ configuration (replaces require('lspconfig'))
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap

		-- Global LSP keymaps when a server attaches
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		-- Completion capabilities
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Diagnostic signs
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- Configure all Mason-installed servers EXCEPT jdtls
		local servers = mason_lspconfig.get_installed_servers()
		for _, server_name in ipairs(servers) do
			if server_name ~= "jdtls" then
				local config_opts = {
					capabilities = capabilities,
				}

				-- Per-server tweaks
				if server_name == "svelte" then
					config_opts.on_attach = function(client, bufnr)
						vim.api.nvim_create_autocmd("BufWritePost", {
							pattern = { "*.js", "*.ts" },
							callback = function(ctx)
								client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
							end,
						})
					end
				elseif server_name == "graphql" then
					config_opts.filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" }
				elseif server_name == "emmet_ls" then
					config_opts.filetypes =
						{ "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" }
				elseif server_name == "lua_ls" then
					config_opts.settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							completion = { callSnippet = "Replace" },
						},
					}
				elseif server_name == "pyright" then
					config_opts.settings = {
						python = {
							analysis = {
								typeCheckingMode = "basic",
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "workspace",
							},
						},
					}
				elseif server_name == "gopls" then
					config_opts.filetypes = { "go", "gomod", "gowork", "gotmpl" }
					config_opts.settings = {
						gopls = {
							usePlaceholders = true,
							completeUnimported = true,
							staticcheck = true,
							analyses = {
								unusedparams = true,
								shadow = true,
								nilness = true,
								unusedwrite = true,
							},
						},
					}
				end

				-- Finalize setup using v0.11 native API
				vim.lsp.config(server_name, config_opts)
				vim.lsp.enable(server_name)
			end
		end

		-- Auto-start JDTLS using the minimal OS-aware config
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = function()
				local ok, jm = pcall(require, "config.java_min")
				if not ok then
					vim.notify("config.java_min not found; JDTLS not started", vim.log.levels.WARN)
					return
				end
				vim.g._java_cmp_caps = capabilities
				jm.setup()
			end,
		})
	end,
}
