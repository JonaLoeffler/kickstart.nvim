return {
  'tpope/vim-fugitive',
  config = function()
    local group = vim.api.nvim_create_augroup('FugitiveLayout', { clear = true })
    local function float_config()
      local width = math.max(1, math.floor(vim.o.columns * 0.9) - 2)
      local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight) * 0.9) - 2)
      return {
        relative = 'editor',
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width - 2) / 2),
        row = math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2),
        border = 'rounded',
        title = ' Git ',
        title_pos = 'center',
      }
    end

    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = group,
      callback = function(event)
        if vim.bo[event.buf].filetype ~= 'fugitive' then
          return
        end
        local window = vim.api.nvim_get_current_win()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == event.buf then
            vim.api.nvim_win_set_config(window, float_config())
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd('WinLeave', {
      group = group,
      callback = function()
        local window = vim.api.nvim_get_current_win()
        if vim.bo.filetype ~= 'fugitive' or vim.api.nvim_win_get_config(window).relative == '' then
          return
        end
        -- Wait until the new window has focus before closing the old one.
        vim.schedule(function()
          -- Interactive staging temporarily opens a Fugitive terminal tab.
          if vim.bo.buftype == 'terminal' and vim.fn.FugitiveGitDir() ~= '' then
            return
          end
          if vim.api.nvim_win_is_valid(window) and vim.api.nvim_get_current_win() ~= window then
            vim.api.nvim_win_close(window, true)
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'FugitiveIndex',
      callback = function()
        local function close_float()
          if vim.api.nvim_win_get_config(0).relative ~= '' then
            vim.api.nvim_win_close(0, true)
          end
        end

        for key, command in pairs {
          ['<CR>'] = 'Gedit',
          ['<2-LeftMouse>'] = 'Gedit',
          o = 'Gsplit',
          gO = 'Gvsplit',
          O = 'Gtabedit',
          p = 'Gpedit',
        } do
          vim.keymap.set('n', key, function()
            local target = vim.fn['fugitive#PorcelainCfile']()
            if target == '' then
              return
            end
            close_float()
            vim.cmd(command .. ' ' .. target)
          end, { buffer = true, silent = true, desc = 'Close Git float and open target' })
        end
        for _, key in ipairs { 'q', '<Esc>' } do
          vim.keymap.set('n', key, close_float, { buffer = true, silent = true, desc = 'Close Git float' })
        end
      end,
    })

    vim.api.nvim_create_autocmd('VimResized', {
      group = group,
      callback = function()
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.bo[vim.api.nvim_win_get_buf(window)].filetype == 'fugitive'
            and vim.api.nvim_win_get_config(window).relative ~= '' then
            vim.api.nvim_win_set_config(window, float_config())
          end
        end
      end,
    })

    vim.keymap.set('n', '<leader>gg', ':Git<CR>')
    vim.keymap.set('n', '<leader>gp', ':Git push<CR>')
    vim.keymap.set('n', '<leader>gP', ':Git pull<CR>')
    vim.keymap.set('n', '<leader>gh', ':0Gclog<CR>')
    vim.keymap.set('n', '<leader>gd', ':Git difftool<CR>')
    vim.keymap.set('n', '<leader>gs', ':Gvdiffsplit<CR>')
    vim.keymap.set('n', '<leader>gx', ':Git mergetool<CR>')

    vim.keymap.set('n', '<leader>gw', ':!gh pr create --web')
  end,
}
