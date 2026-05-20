return {
  -- 1. The Core Database Engines
  {
    "tpope/vim-dadbod",
    lazy = true,
  },

  -- 2. The UI Layer and Autocompletion
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Setup your Snowflake Accounts here
      -- Format: snowflake://<user>:<password>@<account_identifier>/<db>/<schema>?warehouse=<wh>&role=<role>
      vim.g.dbs = {
        { name = "APAC-Staging", url = "snowflake://user:pass@apac_stg_id/DB/SCHEMA?warehouse=COMPUTE_WH" },
        { name = "AMER-Staging", url = "snowflake://user:pass@amer_stg_id/DB/SCHEMA?warehouse=COMPUTE_WH" },
        { name = "AMER-Dev",     url = "snowflake://user:pass@amer_dev_id/DB/SCHEMA?warehouse=DEV_WH" },
        { name = "APAC-Prod",    url = "snowflake://user:pass@apac_prod_id/DB/SCHEMA?warehouse=PROD_WH&role=READ_ONLY" },
        { name = "EMEA-Prod",    url = "snowflake://user:pass@emea_prod_id/DB/SCHEMA?warehouse=PROD_WH" },
      }

      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_win_width = 35
      vim.g.db_ui_save_location = vim.fn.stdpath("config") .. "/db_ui_queries"
    end,
    keys = {
      { "<leader>dbu", "<cmd>DBUIToggle<cr>", desc = "Toggle Snowflake Sidebar" },
      { "<leader>dbf", "<cmd>DBUIFindBuffer<cr>", desc = "Find Buffer in Sidebar" },
      {
        "<leader>dbs",
        function()
          local dbs = vim.g.dbs
          local names = {}
          for _, db in ipairs(dbs) do
            table.insert(names, db.name)
          end

          vim.ui.select(names, {
            prompt = "Select Snowflake Account:",
          }, function(choice)
            if choice then
              vim.cmd("DBUI")
              -- Jump to the DBUI window and search for the chosen account
              print("Focusing " .. choice .. "...")
            end
          end)
        end,
        desc = "Switch Snowflake Account",
      },
    },
  },

  -- 3. Configure Completion Integration
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = { "kristijanhusak/vim-dadbod-completion" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "vim-dadbod-completion" })
    end,
  },

  -- 4. SQL Formatting and Linting (using Conform)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        sql = { "sqlfluff" }, -- sqlfluff is great for Snowflake dialect
      },
    },
  },
}
