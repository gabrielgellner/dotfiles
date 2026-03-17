-- ============================================================================
-- plugins/treesitter.lua
-- Adapted from LazyVim main branch approach for nvim-treesitter main branch.
-- ============================================================================

return {
	-- ── Core treesitter ────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		version = false,
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile", "VeryLazy" },
		opts = {
			ensure_installed = {
				"python",
				"lua",
				"luadoc",
				"vim",
				"vimdoc",
				"toml",
				"yaml",
				"json",
				"markdown",
				"markdown_inline",
				"bash",
				"diff",
				"just",
				"rust",
			},
			matchup = {
				enable = true,
			},
		},
		config = function(_, opts)
			local TS = require("nvim-treesitter")

			-- setup core
			TS.setup(opts)

			-- install any missing parsers from ensure_installed
			local installed = TS.get_installed and TS.get_installed() or {}
			local installed_set = {}
			for _, lang in ipairs(installed) do
				installed_set[lang] = true
			end

			local missing = vim.tbl_filter(function(lang)
				return not installed_set[lang]
			end, opts.ensure_installed or {})

			if #missing > 0 then
				vim.notify(
					"nvim-treesitter: installing missing parsers: " .. table.concat(missing, ", "),
					vim.log.levels.INFO
				)
				TS.install(missing)
			end

			-- wire up highlighting, indent, and folds per filetype
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("nvim_treesitter_ft", { clear = true }),
				callback = function(ev)
					-- highlighting
					pcall(vim.treesitter.start, ev.buf)

					-- treesitter-powered indent
					vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

					-- treesitter-powered folds
					local win = vim.api.nvim_get_current_win()
					if vim.api.nvim_win_get_buf(win) == ev.buf then
						vim.wo[win].foldmethod = "expr"
						vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo[win].foldenable = false -- open all folds by default
					end
				end,
			})
		end,
	},

	-- ── Textobjects ────────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = "VeryLazy",
		opts = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = { query = "@function.outer", desc = "outer function" },
					["if"] = { query = "@function.inner", desc = "inner function" },
					["ac"] = { query = "@class.outer", desc = "outer class" },
					["ic"] = { query = "@class.inner", desc = "inner class" },
					["aa"] = { query = "@parameter.outer", desc = "outer argument" },
					["ia"] = { query = "@parameter.inner", desc = "inner argument" },
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]f"] = "@function.outer",
					["]c"] = "@class.outer",
					["]a"] = "@parameter.inner",
					["]i"] = "@conditional.outer",
					["]l"] = "@loop.outer",
				},
				goto_next_end = {
					["]F"] = "@function.outer",
					["]C"] = "@class.outer",
				},
				goto_previous_start = {
					["[f"] = "@function.outer",
					["[c"] = "@class.outer",
					["[a"] = "@parameter.inner",
					["[i"] = "@conditional.outer",
					["[l"] = "@loop.outer",
				},
				goto_previous_end = {
					["[F"] = "@function.outer",
					["[C"] = "@class.outer",
				},
			},
		},
		config = function(_, opts)
			local TS = require("nvim-treesitter-textobjects")
			if not TS.setup then
				vim.notify("nvim-treesitter-textobjects: please update the plugin", vim.log.levels.ERROR)
				return
			end
			TS.setup(opts)

			-- attach move keymaps per buffer on FileType
			local function attach(buf)
				local all_moves = {
					goto_next_start = opts.move.goto_next_start or {},
					goto_next_end = opts.move.goto_next_end or {},
					goto_previous_start = opts.move.goto_previous_start or {},
					goto_previous_end = opts.move.goto_previous_end or {},
				}

				for method, keymaps in pairs(all_moves) do
					for key, query in pairs(keymaps) do
						local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ")
							.. query:gsub("@", ""):gsub("%..*", "")
							.. (key:sub(2, 2) == key:sub(2, 2):upper() and " end" or " start")

						vim.keymap.set({ "n", "x", "o" }, key, function()
							require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
						end, { buffer = buf, desc = desc, silent = true })
					end
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("nvim_treesitter_textobjects", { clear = true }),
				callback = function(ev)
					attach(ev.buf)
				end,
			})

			-- attach to already open buffers
			vim.tbl_map(attach, vim.api.nvim_list_bufs())
		end,
	},
}
