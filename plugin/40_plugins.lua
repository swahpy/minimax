-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  add({
    source = "nvim-treesitter/nvim-treesitter",
    -- Update tree-sitter parser after plugin is updated
    hooks = {
      post_checkout = function()
        vim.cmd("TSUpdate")
      end,
    },
  })
  add({
    source = "nvim-treesitter/nvim-treesitter-textobjects",
    -- Use `main` branch since `master` branch is frozen, yet still default
    -- It is needed for compatibility with 'nvim-treesitter' `main` branch
    checkout = "main",
  })

  -- Define languages which will have parsers installed and auto enabled
  local languages = {
    -- These are already pre-installed with Neovim. Used as an example.
    "lua",
    "vimdoc",
    "markdown",
    -- Add here more languages with which you want to use tree-sitter
    -- To see available languages:
    -- - Execute `:=require('nvim-treesitter').get_available()`
    -- - Visit 'SUPPORTED_LANGUAGES.md' file at
    --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
    "vim",
    "query",
    "json",
    "yaml",
    "printf",
    "toml",
    "markdown_inline",
    "bash",
    "go",
    "gomod",
    "gowork",
    "gosum",
    "python",
    "regex",
    "html",
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then
    require("nvim-treesitter").install(to_install)
  end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev)
    vim.treesitter.start(ev.buf)
  end
  _G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
  add("neovim/nvim-lspconfig")

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
  vim.lsp.enable({
    "lua_ls",
    "gopls",
    "emmet_language_server",
    "vtsls",
  })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add("stevearc/conform.nvim")

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require("conform").setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = "fallback",
    },
    formatters_by_ft = {
      css = { "biome" },
      go = { "goimports", "gofumpt" },
      html = { "superhtml" },
      javascript = { "biome" },
      json = { "biome" },
      lua = { "stylua" },
      markdown = { "prettier" },
      python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
      toml = { "taplo" },
      xml = { "xmllint" },
      yaml = { "yq" },
    },
  })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
  add("rafamadriz/friendly-snippets")
end)

-- Others ===================================================================

-- 'mbbill/undotree' visualizes the undo history and makes it easy to browse and switch
-- between different undo branches.
now_if_args(function()
  add("mbbill/undotree")

  vim.g.undotree_ShortIndicators = 1
  vim.g.undotree_DiffAutoOpen = 0
  vim.g.undotree_SetFocusWhenToggle = 1
end)

-- 'obsidian-nvim/obsidian.nvim' built for people who love the concept of Obsidian:
-- a simple, markdown-based notes app, but love Neovim too much to stand typing
-- characters into anything else.
now_if_args(function()
  add("obsidian-nvim/obsidian.nvim")
  local function get_current_datetime_string()
    return os.date("%Y-%m-%d %H:%M:%S") -- Example: 2025-10-14 10:30:00
  end
  require("obsidian").setup({
    legacy_commands = false,
    frontmatter = {
      enabled = true,
      func = function(note)
        local now = get_current_datetime_string()
        local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        -- Preserve existing metadata fields first
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        -- Set 'created' only if it doesn't exist
        if out.created == nil then
          out.created = now
        end
        -- Always update 'updated'
        out.updated = now
        return out
      end,
      sort = { "id", "aliases", "tags", "created", "updated" },
    },
    notes_subdir = "notes",
    new_notes_location = "notes",
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,
    wiki_link_func = require("obsidian.builtin").wiki_link_path_only,
    workspaces = {
      { name = "swahpy", path = "~/workspace/vaults/swahpy" },
      -- {
      --   name = "no-vault",
      --   path = function()
      --     -- alternatively use the CWD:
      --     -- return assert(vim.fn.getcwd())
      --     return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
      --   end,
      --   overrides = {
      --     notes_subdir = vim.NIL, -- have to use 'vim.NIL' instead of 'nil'
      --     new_notes_location = "current_dir",
      --     templates = {
      --       folder = vim.NIL,
      --     },
      --     disable_frontmatter = true,
      --   },
      -- },
    },
    daily_notes = {
      folder = "dailies",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      workdays_only = false,
    },
    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {},
    },
    checkbox = {
      order = { " ", "x" },
    },
  })
end)

-- 'MeanderingProgrammer/render-markdown.nvim' improves viewing Markdown files in Neovim
now_if_args(function()
  add("MeanderingProgrammer/render-markdown.nvim")
  require("render-markdown").setup({
    -- Pre configured settings that will attempt to mimic various target user experiences.
    -- User provided settings will take precedence.
    -- | obsidian | mimic Obsidian UI                                          |
    -- | lazy     | will attempt to stay up to date with LazyVim configuration |
    -- | none     | does nothing                                               |
    preset = "obsidian",
    -- Filetypes this plugin will run on.
    file_types = { "markdown", "codecompanion" },
    completions = { lsp = { enabled = true } },
  })
end)

-- 'zbirenbaum/copilot.lua' is the pure lua replacement for github/copilot.vim.
later(function()
  add("zbirenbaum/copilot.lua")
  require("copilot").setup({
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = "<M-i>",
      },
    },
  })
end)

-- 'github/copilot.vim' is a Vim/Neovim plugin for GitHub Copilot.
-- later(function()
--   add("github/copilot.vim")
-- end)

-- 'olimorris/codecompanion.nvim' enables Code with LLMs and Agents via the in-built adapters,
-- the community adapters or by building your own.
later(function()
  add({
    source = "olimorris/codecompanion.nvim",
    -- checkout = "v18.4.1",
    -- monitor = "main",
    depends = { "nvim-lua/plenary.nvim", "ravitemer/mcphub.nvim" },
    hooks = {
      post_checkout = function()
        vim.cmd("npm install -g mcp-hub@latest")
      end,
    },
  })
  -- setup mcphub
  require("mcphub").setup()
  -- setup codecompanion
  require("codecompanion").setup({
    interactions = {
      chat = {
        -- You can specify an adapter by name and model (both ACP and HTTP)
        adapter = {
          name = "copilot",
          model = "gpt-5",
        },
      },
      -- Or, just specify the adapter by name
      inline = {
        adapter = "copilot",
        model = "gpt-5",
      },
      cmd = {
        adapter = "copilot",
        model = "gpt-5",
      },
      background = {
        adapter = {
          name = "copilot",
          model = "gpt-5",
        },
      },
    },
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true,
        },
      },
    },
    adapters = {
      http = {
        aiwave = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              api_key = "AIWAVE_API_KEY",
              url = function()
                return os.getenv("AIWAVE_URL")
              end,
            },
            schema = {
              model = {
                order = 1,
                mapping = "parameters",
                type = "enum",
                desc = "aiwave",
                default = "gemini-3-pro-preview",
                choices = {
                  "gemini-flash-latest",
                  "gemini-pro-latest",
                  "gemini-3-pro-preview",
                },
              },
              max_tokens = {
                order = 2,
                default = 9999,
              },
            },
          })
        end,
      },
    },
  })
  vim.cmd([[cab cc CodeCompanion]])
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
now_if_args(function()
  add("mason-org/mason.nvim")
  require("mason").setup()
end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
-- MiniDeps.now(function()
--   -- Install only those that you need
--   add('sainnhe/everforest')
--   add('Shatur/neovim-ayu')
--   add('ellisonleao/gruvbox.nvim')
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)
