return {
	"chrisgrieser/nvim-spider",
	lazy = true,
	opts = {
		skipInsignificantPunctuation = false,
	},
	keys = {
		{
			"w",
			function()
				require("spider").motion("w")
			end,
			mode = { "n", "o", "x" },
			desc = "Spider word forward",
		},
		{
			"e",
			function()
				require("spider").motion("e")
			end,
			mode = { "n", "o", "x" },
			desc = "Spider word end",
		},
		{
			"b",
			function()
				require("spider").motion("b")
			end,
			mode = { "n", "o", "x" },
			desc = "Spider word back",
		},
		{
			"ge",
			function()
				require("spider").motion("ge")
			end,
			mode = { "n", "o", "x" },
			desc = "Spider word end back",
		},
	},
}
