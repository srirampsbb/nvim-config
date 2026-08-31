vim.pack.add({
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
})

require("diffview").setup({
  hg_cmd = nil, -- Suppresses the missing 'hg' executable check
})
