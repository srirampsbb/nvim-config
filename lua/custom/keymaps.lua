-- Yank entire file contents directly to the system clipboard (+ register)
vim.keymap.set("n", "<leader>ya", ":%y+<CR>", { desc = "Yank all lines to clipboard", silent = true })
