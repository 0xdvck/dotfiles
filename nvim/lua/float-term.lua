function FloatTerm(...)
  -- Get dimensions with fallback
  local lines = tonumber(vim.o.lines) or 24
  local columns = tonumber(vim.o.columns) or 80

  if not lines or not columns then
    error("Invalid Neovim configuration: Unable to fetch dimensions.")
    return
  end

  -- Configuration
  local height = math.floor((lines - 2) * 0.6)
  local row = math.floor((lines - height) / 2)
  local width = math.floor(columns * 0.6)
  local col = math.floor((columns - width) / 2)

  -- Border Window Options
  local border_opts = {
    relative = 'editor',
    row = row - 1,
    col = col - 2,
    width = width + 4,
    height = height + 2,
    style = 'minimal'
  }

  -- Terminal Window Options
  local opts = {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal'
  }

  -- Create border content
  local top = "╭" .. string.rep("─", width + 2) .. "╮"
  local mid = "│" .. string.rep(" ", width + 2) .. "│"
  local bot = "╰" .. string.rep("─", width + 2) .. "╯"
  local lines = {top}
  for _ = 1, height do
    table.insert(lines, mid)
  end
  table.insert(lines, bot)

  -- Create border buffer and window
  local bbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bbuf, 0, -1, true, lines)
  local border_win = vim.api.nvim_open_win(bbuf, true, border_opts)

  -- Create terminal buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  local term_win = vim.api.nvim_open_win(buf, true, opts)

  -- Styling
  vim.cmd("hi FloatWinBorder guifg=#87bb7c")
  vim.api.nvim_win_set_option(border_win, 'winhl', 'Normal:FloatWinBorder')
  vim.api.nvim_win_set_option(term_win, 'winhl', 'Normal:Normal')

  -- Open terminal
  if select('#', ...) == 0 then
    vim.cmd("terminal")
  else
    vim.fn.termopen(...)
  end
  vim.cmd("startinsert")

  -- Close border and terminal windows when the terminal closes
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(border_win) then
        vim.api.nvim_win_close(border_win, true)
      end
      if vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, true)
      end
      vim.api.nvim_buf_delete(bbuf, {force = true})
    end
  })

  -- Re-enter insert mode when switching back to terminal window
  vim.api.nvim_create_autocmd("WinEnter", {
    buffer = buf,
    callback = function()
      vim.cmd("startinsert")
    end
  })
end

-- esc to normal mode in terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
-- open terminal without spamming new windows
vim.keymap.set("n", "<leader>t", FloatTerm)
