vim.pack.add {
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
}

require('diffview').setup {
  hg_cmd = nil, -- Suppresses the missing 'hg' executable check
}

-- List local branches and open Diffview against selection
local function pick_branch_diff()
  local handle = io.popen 'git branch --format "%(refname:short)"'
  if not handle then return end
  local result = handle:read '*a'
  handle:close()

  local branches = {}
  for branch in result:gmatch '[^\n]+' do
    table.insert(branches, branch)
  end

  vim.schedule(function()
    vim.ui.select(branches, {}, function(choice)
      if choice then vim.cmd('DiffviewOpen ' .. choice) end
    end)
  end)
end

-- List remote branches and open Diffview against selection
local function pick_remote_branch_diff()
  local handle = io.popen 'git branch -r'
  if not handle then return end
  local result = handle:read '*a'
  handle:close()

  local branches = {}
  for line in result:gmatch '[^\n]+' do
    local branch = line:gsub('^%s*[*%+%s]*%s*', ''):gsub('%s+$', '')
    table.insert(branches, branch)
  end

  vim.schedule(function()
    vim.ui.select(branches, {}, function(choice)
      if choice then vim.cmd('DiffviewOpen ' .. choice) end
    end)
  end)
end

vim.keymap.set('n', '<leader>dvl', pick_branch_diff, { desc = 'Diffview against local branch' })
vim.keymap.set('n', '<leader>dvr', pick_remote_branch_diff, { desc = 'Diffview against remote branch' })
vim.keymap.set('n', '<leader>dvh', ':DiffviewOpen HEAD<CR>', { desc = 'Diffview against HEAD' })
vim.keymap.set('n', '<leader>dvu', ':DiffviewOpen @{upstream}<CR>', { desc = 'Diffview against upstream branch' })
vim.keymap.set('n', '<leader>dvc', ':DiffviewClose<CR>', { desc = 'Diffview [C]lose' })