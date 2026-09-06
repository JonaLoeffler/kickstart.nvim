return {
  'udalov/kotlin-vim',
  ft = { 'kotlin' },
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'kotlin',
      callback = function()
        vim.opt_local.colorcolumn = '130'
        vim.opt_local.textwidth = 130
      end,
    })
  end,
}
