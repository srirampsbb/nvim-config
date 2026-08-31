vim.pack.add({
  'https://github.com/pwntester/octo.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
})

require('octo').setup({
  use_diagnostic_signs = true,
  picker = 'telescope',
})
