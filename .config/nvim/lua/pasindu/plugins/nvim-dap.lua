return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local dap_python = require("dap-python")

			local python_path = "/Users/pasindudiss/.asdf/installs/python/3.13.3/bin/python3"

			local function ensure_python_package(pkg)
				local handle = io.popen(python_path .. ' -c "import ' .. pkg .. '" 2>&1')
				local result = handle:read("*a")
				handle:close()

				if result:find("ModuleNotFoundError") then
					vim.notify("Installing " .. pkg .. " for nvim-dap-python...", vim.log.levels.INFO)
					local install_result = vim.fn.system({ python_path, "-m", "pip", "install", pkg })
					if
						install_result:find("Successfully installed")
						or install_result:find("Requirement already satisfied")
					then
						vim.notify(pkg .. " installed successfully!", vim.log.levels.INFO)
					else
						vim.notify("Failed to install " .. pkg .. ":\n" .. install_result, vim.log.levels.ERROR)
					end
				end
			end

			ensure_python_package("debugpy")
			ensure_python_package("pytest")

			dapui.setup({})
			require("nvim-dap-virtual-text").setup({
				commented = true,
			})

			dap_python.setup(python_path)
			dap_python.test_runner = "pytest"

			vim.fn.sign_define("DapBreakpoint", {
				text = "",
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = "",
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = "",
				texthl = "DiagnosticSignWarn",
				linehl = "Visual",
				numhl = "DiagnosticSignWarn",
			})

			-- Only auto-open DAP UI; do not auto-close
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			-- Removed auto-close on terminated and exited

			local opts = { noremap = true, silent = true }

			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {
				desc = "DAP: Toggle Breakpoint",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>dc", dap.continue, {
				desc = "DAP: Continue/Start",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>do", dap.step_over, {
				desc = "DAP: Step Over",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>di", dap.step_into, {
				desc = "DAP: Step Into",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>dO", dap.step_out, {
				desc = "DAP: Step Out",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>dq", dap.terminate, {
				desc = "DAP: Quit Debugger",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>du", dapui.toggle, {
				desc = "DAP: Toggle UI",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>dt", dap_python.test_method, {
				desc = "DAP: Debug Python Test Method",
				noremap = true,
				silent = true,
			})
			vim.keymap.set("n", "<leader>dT", dap_python.test_class, {
				desc = "DAP: Debug Python Test Class",
				noremap = true,
				silent = true,
			})
		end,
	},
}
