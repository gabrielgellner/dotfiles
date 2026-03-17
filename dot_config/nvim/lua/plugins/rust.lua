-- rustaceanvim - LSP + rust-specific features
return {
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false,
		config = function()
			vim.g.rustaceanvim = {
				server = {
					settings = {
						["rust-analyzer"] = {
							checkOnSave = {
								command = "clippy", -- use clippy instead of cargo check
							},
							inlayHints = {
								bindingModeHints = { enable = true },
								chainingHints = { enable = true },
								closureReturnTypeHints = { enable = "always" },
								typeHints = { enable = true },
							},
							cargo = {
								allFeatures = true,
							},
							preferredMRO = "markdown",
						},
					},
				},
			}
		end,
	},
	-- crates.nvim - dependency version hints in Cargo.toml
	{
		"saecki/crates.nvim",
		event = "BufRead Cargo.toml",
		config = function()
			require("crates").setup()
		end,
	},
}
