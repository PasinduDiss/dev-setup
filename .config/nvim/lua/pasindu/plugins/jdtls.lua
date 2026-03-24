return {
	"mfussenegger/nvim-jdtls",
	ft = { "java" },
	config = function()
		local uv, fn, api = vim.loop, vim.fn, vim.api
		local home = uv.os_homedir()

		---------------------------------------------------------------------------
		-- Paths & env
		---------------------------------------------------------------------------
		-- Ensure Neovim sees asdf shims (even when launched from GUI)
		local asdf_shims = home .. "/.asdf/shims"
		if uv.fs_stat(asdf_shims) and (not string.find(vim.env.PATH or "", asdf_shims, 1, true)) then
			vim.env.PATH = asdf_shims .. ":" .. (vim.env.PATH or "")
		end

		-- Mason roots
		local mason_root = os.getenv("MASON") or (fn.stdpath("data") .. "/mason")
		local jdtls_root = mason_root .. "/packages/jdtls"

		-- Equinox launcher
		local equinox = fn.globpath(jdtls_root .. "/plugins", "org.eclipse.equinox.launcher_*.jar", false, true)[1]
		if not equinox or equinox == "" then
			vim.notify("JDTLS: launcher not found under " .. jdtls_root, vim.log.levels.ERROR)
			return
		end

		-- OS-specific config dir
		local sys = uv.os_uname().sysname
		local jdtls_config = jdtls_root .. ((sys == "Darwin") and "/config_mac" or "/config_linux")
		if not uv.fs_stat(jdtls_config) then
			vim.notify("JDTLS: missing config dir: " .. jdtls_config, vim.log.levels.ERROR)
			return
		end

		-- Java runtime (prefer asdf shim)
		local java = (uv.fs_stat(asdf_shims .. "/java") and (asdf_shims .. "/java")) or fn.exepath("java") or "java"

		---------------------------------------------------------------------------
		-- Optional agents
		---------------------------------------------------------------------------
		local lombok_path = jdtls_root .. "/lombok.jar"
		local lombok_arg = uv.fs_stat(lombok_path) and ("-javaagent:" .. lombok_path) or nil

		local logback_xml = home .. "/.config/jdtls/logback.xml"
		local logback_arg = uv.fs_stat(logback_xml) and ("-Dlogback.configurationFile=" .. logback_xml) or nil

		---------------------------------------------------------------------------
		-- Debug & Test bundles (auto-detected if installed via Mason)
		---------------------------------------------------------------------------
		local bundles = {}
		local function add_bundle(pkg, relglob)
			local base = mason_root .. "/packages/" .. pkg
			if uv.fs_stat(base) then
				local jars = vim.split(fn.glob(base .. "/" .. relglob, 1), "\n", { trimempty = true })
				vim.list_extend(bundles, jars)
			end
		end
		add_bundle("java-debug-adapter", "extension/server/com.microsoft.java.debug.plugin-*.jar")
		add_bundle("java-test", "extension/server/*.jar")

		---------------------------------------------------------------------------
		-- Decompiler detection: Vineflower -> FernFlower -> none
		---------------------------------------------------------------------------
		local vine =
			fn.globpath(jdtls_root .. "/plugins", "org.eclipse.jdt.ls.decompiler.vineflower_*.jar", false, true)[1]
		local fern =
			fn.globpath(jdtls_root .. "/plugins", "org.eclipse.jdt.ls.decompiler.fernflower_*.jar", false, true)[1]
		local preferred_decompiler = (vine and vine ~= "") and "vineflower"
			or ((fern and fern ~= "") and "fernflower" or "none")

		if preferred_decompiler == "none" then
			vim.notify(
				"JDTLS: no decompiler plugin detected (vineflower/fernflower). "
					.. "Gradle-attached sources will still open; decompilation won't.",
				vim.log.levels.WARN
			)
		end

		---------------------------------------------------------------------------
		-- Base command (workspace added per project on start)
		---------------------------------------------------------------------------
		local base_cmd = vim.tbl_filter(function(x)
			return x and x ~= ""
		end, {
			java,
			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			"-Dosgi.bundles.defaultStartLevel=4",
			"-Dfile.encoding=UTF-8",
			logback_arg,
			lombok_arg,
			"-Xms1g",
			"--add-opens",
			"java.base/java.util=ALL-UNNAMED",
			"--add-opens",
			"java.base/java.lang=ALL-UNNAMED",
			"-jar",
			equinox,
			"-configuration",
			jdtls_config,
			-- "-data" <workspace> appended in start()
		})

		---------------------------------------------------------------------------
		-- Settings (Gradle + decompiler + quality-of-life)
		---------------------------------------------------------------------------
		local settings = {
			java = {
				contentProvider = { preferred = preferred_decompiler }, -- vineflower/fernflower/none
				configuration = {
					updateBuildConfiguration = "interactive", -- "automatic" if you like
				},
				import = {
					gradle = {
						enabled = true,
						wrapper = { enabled = true }, -- use ./gradlew if present
						offline = { enabled = false }, -- set true for cache-only imports
						java = { home = nil }, -- e.g. "/Users/you/.asdf/installs/java/temurin-21.0.1"
					},
					maven = { enabled = true }, -- harmless if unused
				},
				gradle = { wrapper = { enabled = true } },
				signatureHelp = { enabled = true },
				completion = {
					favoriteStaticMembers = {
						"org.hamcrest.MatcherAssert.assertThat",
						"org.hamcrest.Matchers.*",
						"org.junit.jupiter.api.Assertions.*",
						"java.util.Objects.requireNonNull",
						"java.util.Objects.requireNonNullElse",
					},
				},
				sources = { organizeImports = { starThreshold = 999, staticStarThreshold = 999 } },
				codeGeneration = {
					toString = { template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
					hashCodeEquals = { useJava7Objects = true },
					useBlocks = true,
				},
				format = { enabled = true },
			},
		}

		---------------------------------------------------------------------------
		-- Test Results Buffer
		---------------------------------------------------------------------------
		local test_results = {
			buf = nil,
			win = nil,
			output = {},
			status = "idle", -- idle, running, passed, failed
			test_name = "",
		}

		local function create_test_results_buf()
			if test_results.buf and api.nvim_buf_is_valid(test_results.buf) then
				return test_results.buf
			end
			test_results.buf = api.nvim_create_buf(false, true)
			api.nvim_buf_set_option(test_results.buf, "buftype", "nofile")
			api.nvim_buf_set_option(test_results.buf, "bufhidden", "hide")
			api.nvim_buf_set_option(test_results.buf, "swapfile", false)
			api.nvim_buf_set_name(test_results.buf, "Java Test Results")
			return test_results.buf
		end

		local function update_test_results_buf()
			local buf = create_test_results_buf()
			local lines = {}

			-- Header with status
			local status_icon = ({
				idle = "○",
				running = "◐",
				passed = "✓",
				failed = "✗",
			})[test_results.status] or "?"

			local status_hl = ({
				idle = "Comment",
				running = "DiagnosticWarn",
				passed = "DiagnosticOk",
				failed = "DiagnosticError",
			})[test_results.status] or "Normal"

			table.insert(lines, string.format(" %s %s", status_icon, test_results.test_name))
			table.insert(lines, string.rep("─", 60))
			table.insert(lines, "")

			for _, line in ipairs(test_results.output) do
				table.insert(lines, line)
			end

			api.nvim_buf_set_option(buf, "modifiable", true)
			api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			api.nvim_buf_set_option(buf, "modifiable", false)

			-- Highlight the status line
			if api.nvim_buf_is_valid(buf) then
				api.nvim_buf_add_highlight(buf, -1, status_hl, 0, 0, -1)
			end
		end

		local function open_test_results_window()
			local buf = create_test_results_buf()
			update_test_results_buf()

			-- Close existing window if open
			if test_results.win and api.nvim_win_is_valid(test_results.win) then
				api.nvim_set_current_win(test_results.win)
				return
			end

			-- Open in a right split
			vim.cmd("botright vsplit")
			test_results.win = api.nvim_get_current_win()
			api.nvim_win_set_buf(test_results.win, buf)
			api.nvim_win_set_width(test_results.win, 80)
			api.nvim_win_set_option(test_results.win, "number", false)
			api.nvim_win_set_option(test_results.win, "relativenumber", false)
			api.nvim_win_set_option(test_results.win, "signcolumn", "no")

			-- Keymap to close
			api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
		end

		local function run_test_with_output(test_fn, test_name)
			-- Reset state
			test_results.output = {}
			test_results.status = "running"
			test_results.test_name = test_name

			vim.notify("Running: " .. test_name, vim.log.levels.INFO)
			update_test_results_buf()

			-- Set up DAP listener for output
			local dap = require("dap")

			local output_listener = function(_, body)
				if body.output then
					local lines = vim.split(body.output, "\n", { trimempty = false })
					for _, line in ipairs(lines) do
						if line ~= "" then
							table.insert(test_results.output, line)
						end
					end
					update_test_results_buf()

					-- Auto-scroll if window is open
					if test_results.win and api.nvim_win_is_valid(test_results.win) then
						local line_count = api.nvim_buf_line_count(test_results.buf)
						api.nvim_win_set_cursor(test_results.win, { line_count, 0 })
					end
				end
			end

			local terminated_listener = function()
				-- Check output for pass/fail
				local output_text = table.concat(test_results.output, "\n")
				if output_text:match("FAILURES") or output_text:match("AssertionError") or output_text:match("Exception") then
					test_results.status = "failed"
					vim.notify("Test FAILED: " .. test_name, vim.log.levels.ERROR)
				else
					test_results.status = "passed"
					vim.notify("Test PASSED: " .. test_name, vim.log.levels.INFO)
				end
				update_test_results_buf()

				-- Clean up listeners
				dap.listeners.after.event_output["jdtls_test"] = nil
				dap.listeners.after.event_terminated["jdtls_test"] = nil
				dap.listeners.after.event_exited["jdtls_test"] = nil
			end

			dap.listeners.after.event_output["jdtls_test"] = output_listener
			dap.listeners.after.event_terminated["jdtls_test"] = terminated_listener
			dap.listeners.after.event_exited["jdtls_test"] = terminated_listener

			-- Run the test
			test_fn()
		end

		---------------------------------------------------------------------------
		-- on_attach
		---------------------------------------------------------------------------
		local function on_attach(_, bufnr)
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "JDTLS: " .. (desc or "") })
			end

			-- Standard LSP
			map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
			map("n", "gr", vim.lsp.buf.references, "References")
			map("n", "K", vim.lsp.buf.hover, "Hover")
			map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
			map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")

			-- JDTLS extras
			local j = require("jdtls")
			map("n", "<leader>jo", j.organize_imports, "Organize Imports")
			map("n", "<leader>je", j.extract_variable, "Extract Variable")
			map("v", "<leader>je", j.extract_variable, "Extract Variable (sel)")
			map("v", "<leader>jm", j.extract_method, "Extract Method (sel)")

			-- Enhanced test commands with output capture
			map("n", "<leader>jt", function()
				local cursor = api.nvim_win_get_cursor(0)
				local line = api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""
				local method_name = line:match("void%s+(%w+)") or line:match("public%s+void%s+(%w+)") or "test"
				run_test_with_output(j.test_nearest_method, method_name)
			end, "Test Method")

			map("n", "<leader>jT", function()
				local filename = fn.expand("%:t:r")
				run_test_with_output(j.test_class, filename)
			end, "Test Class")

			-- View test results
			map("n", "<leader>jr", open_test_results_window, "Test Results")

			-- DAP
			if #bundles > 0 then
				require("jdtls").setup_dap({ hotcodereplace = "auto" })
				require("jdtls.dap").setup_dap_main_class_configs()
			end
		end

		---------------------------------------------------------------------------
		-- Helpers
		---------------------------------------------------------------------------
		local root_markers = {
			"gradlew",
			"build.gradle",
			"build.gradle.kts",
			"settings.gradle",
			"settings.gradle.kts",
			"mvnw",
			"pom.xml",
			".git",
		}

		local function find_formatter_files(root)
			local xml = root .. "/styling/eclipse-formatter.xml"
			if vim.loop.fs_stat(xml) then
				return { url = "file://" .. xml, profile = "GoogleStyle for CCH" }
			end

			local prefs = root .. "/.settings/org.eclipse.jdt.core.prefs"
			if vim.loop.fs_stat(prefs) then
				return { url = "file://" .. prefs, profile = nil }
			end

			return nil
		end

		local function compute_workspace(root)
			local project = fn.fnamemodify(root, ":p:h:t")
			local workspace = home .. "/.local/share/eclipse/" .. project
			fn.mkdir(workspace, "p")
			return workspace
		end

		local function start_jdtls_for_dir(dir)
			local jdtls = require("jdtls")
			local root = require("jdtls.setup").find_root(root_markers) or dir
			local workspace = compute_workspace(root)
			local cmd = vim.list_extend(vim.deepcopy(base_cmd), { "-data", workspace })

			-- Per-project formatter wiring
			local s = vim.deepcopy(settings)
			local fmt = find_formatter_files(root)
			if fmt then
				s.java.format = s.java.format or {}
				s.java.format.enabled = true
				s.java.format.settings = s.java.format.settings or {}
				s.java.format.settings.url = fmt.url
				s.java.format.settings.profile = fmt.profile
			end

			jdtls.start_or_attach({
				cmd = cmd,
				root_dir = root,
				on_attach = on_attach,
				settings = s,
				init_options = { bundles = bundles },
			})
		end

		-- Java 21 runtime sanity check (once)
		local checked_java = false
		local function ensure_java21_once()
			if checked_java then
				return
			end
			checked_java = true
			vim.system({ java, "-version" }, { text = true }, function(res)
				local out = (res.stderr or "") .. (res.stdout or "")
				if not out:match('version%s+"21') then
					vim.schedule(function()
						vim.notify(
							"JDTLS: Java 21 runtime recommended. Current: " .. out:gsub("\n", " "),
							vim.log.levels.WARN
						)
					end)
				end
			end)
		end

		---------------------------------------------------------------------------
		-- Autocommands
		---------------------------------------------------------------------------
		-- 1) Real Java files: start/attach normally
		api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = function()
				ensure_java21_once()
				start_jdtls_for_dir(fn.getcwd())
			end,
			desc = "Start/attach JDTLS for Java buffers",
		})

		-- 2) jdt:// classfiles: attach first, then open via URI (NOT bufnr)
		api.nvim_create_autocmd("BufReadCmd", {
			pattern = "jdt://*",
			callback = function(args)
				ensure_java21_once()
				start_jdtls_for_dir(fn.getcwd())
				local uri = vim.api.nvim_buf_get_name(args.buf) -- jdt://… URI string
				vim.schedule(function()
					local ok, err = pcall(require("jdtls").open_classfile, uri)
					if not ok then
						vim.notify("JDTLS open_classfile failed: " .. tostring(err), vim.log.levels.WARN)
					end
				end)
			end,
			desc = "Attach JDTLS before opening jdt:// classfiles",
		})
	end,
}
