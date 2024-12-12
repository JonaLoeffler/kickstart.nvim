local M = {}

M.setup = function()
  -- Ensure ktlint is installed and available
  local ktlint = vim.fn.executable 'ktlint'
  if not ktlint then
    print "Error: ktlint not found. Please install it and ensure it's in your PATH."
    return
  end

  -- Function to run ktlint
  local function run_ktlint()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then
      print 'No file opened for formatting.'
      return
    end

    -- Run ktlint asynchronously
    vim.cmd [[execute 'silent! !ktlint -F %']]
  end

  -- Set up autocommand to format on save
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    group = vim.api.nvim_create_augroup('FormatWithKtlint', {}),
    pattern = { '*.kt', '*.kts' },
    command = ':silent! :!ktlint -F %',
  })

  -- Add a command to manually trigger formatting
  vim.api.nvim_create_user_command('FormatWithKtlint', run_ktlint, {})
end

return M
