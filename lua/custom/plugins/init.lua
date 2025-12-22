-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
vim.cmd.packadd 'cfilter'

return {
  {
    'gisketch/triforce.nvim',
    dependencies = {
      'nvzone/volt',
    },
    config = function()
      require('triforce').setup {
        -- Optional: Add your configuration here
        keymap = {
          show_profile = '<leader>tp', -- Open profile with <leader>tp
        },
      }
    end,
  },
}
