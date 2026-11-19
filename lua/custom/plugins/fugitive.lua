return {
  'tpope/vim-fugitive',
  config = function()
    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = vim.api.nvim_create_augroup('FugitiveLayout', { clear = true }),
      callback = function(event)
        if vim.bo[event.buf].filetype ~= 'fugitive' then
          return
        end
        local window = vim.api.nvim_get_current_win()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == event.buf then
            vim.api.nvim_win_call(window, function()
              vim.cmd 'wincmd H'
            end)
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      group = 'FugitiveLayout',
      pattern = 'FugitiveIndex',
      callback = function()
        local function open_target(command)
          local target = vim.fn['fugitive#PorcelainCfile']()
          if target == '' then
            return
          end

          local status_window = vim.api.nvim_get_current_win()
          vim.cmd.wincmd 'H'
          if #vim.api.nvim_tabpage_list_wins(0) == 1 then
            vim.cmd 'rightbelow vsplit'
          else
            vim.cmd.wincmd 'l'
          end
          vim.cmd(command .. ' ' .. target)
          vim.api.nvim_win_call(status_window, function()
            vim.cmd.wincmd 'H'
          end)
        end

        for key, command in pairs { ['<CR>'] = 'Gedit', ['<2-LeftMouse>'] = 'Gedit', o = 'Gsplit', gO = 'Gvsplit' } do
          vim.keymap.set('n', key, function()
            open_target(command)
          end, { buffer = true, silent = true, desc = 'Open Fugitive target on the right' })
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
