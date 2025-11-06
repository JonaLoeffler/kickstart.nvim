--[[
  Jira Branch Creator Plugin
  
  This plugin replicates the lazygit Jira ticket workflow for creating branches.
  
  Features:
  - Fetches your assigned Jira tickets (excluding Done/Rejected)
  - Uses Telescope for an interactive ticket picker
  - Prompts for branch description (uses ticket summary if left empty)
  - Automatically creates branch with format: feature/ECO-123-slugified-description
  - Immediately checks out the new branch
  
  Requirements:
  1. The 'jira' CLI tool must be installed and configured
     (https://github.com/ankitpokhrel/jira-cli)
  2. Git must be available in your PATH
  
  Configuration:
  - Update JIRA_EMAIL below with your Jira account email
  
  Usage:
  - Press <leader>gt in normal mode to open the ticket picker
  - Select a ticket from the Telescope picker (e.g., ECO-123)
  - Enter a branch description (or leave empty to use ticket summary)
  - Branch will be created and checked out as: feature/ECO-123-slugified-description
  
  Examples:
    Ticket: ECO-456 "Implement user authentication"
    Description: "Fix user authentication bug"
    Result: feature/ECO-456-fix-user-authentication-bug
    
    Ticket: ECO-789 "Add dark mode support"
    Description: (empty)
    Result: feature/ECO-789-add-dark-mode-support
--]]

-- Module for creating git branches from Jira tickets
local M = {}

-- ============================================================================
-- CONFIGURATION - Update this with your email
-- ============================================================================
local JIRA_EMAIL = os.getenv('JIRA_EMAIL')

-- Function to fetch Jira tickets
local function fetch_jira_tickets()
  local cmd = string.format('jira issue list --plain --no-headers --columns key,summary -s~Done -s~Rejected -a"%s"', JIRA_EMAIL)

  local handle = io.popen(cmd)
  if not handle then
    vim.notify('Failed to run Jira command', vim.log.levels.ERROR)
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if not result or result == '' then
    vim.notify('No Jira tickets found', vim.log.levels.WARN)
    return nil
  end

  -- Parse the output into a table of tickets
  local tickets = {}
  for line in result:gmatch '[^\r\n]+' do
    -- Match pattern: KEY<whitespace>SUMMARY
    local key, summary = line:match '^([A-Z]+-[0-9]+)%s+(.+)$'
    if key and summary then
      table.insert(tickets, {
        key = key,
        summary = summary,
        display = key .. ': ' .. summary,
      })
    end
  end

  return tickets
end

-- Function to slugify a string (lowercase, replace spaces with hyphens, remove special chars)
local function slugify(text)
  -- Convert to lowercase
  text = text:lower()
  -- Replace spaces and underscores with hyphens
  text = text:gsub('[%s_]+', '-')
  -- Remove special characters, keep only alphanumeric and hyphens
  text = text:gsub('[^%w%-]', '')
  -- Remove leading/trailing hyphens
  text = text:gsub('^%-+', ''):gsub('%-+$', '')
  -- Collapse multiple hyphens into one
  text = text:gsub('%-+', '-')
  return text
end

-- Function to create and checkout branch
local function create_git_branch(ticket_key, branch_description, ticket_summary)
  -- Use the provided description, or fall back to the ticket summary if empty
  local description_to_use = (branch_description and branch_description ~= '') and branch_description or ticket_summary

  -- Slugify the description
  local slugified_description = slugify(description_to_use)

  -- Construct branch name: feature/ECO-123-slugified-description
  local branch_name = string.format('feature/%s-%s', ticket_key, slugified_description)

  -- Use git checkout -b to create and immediately checkout the branch
  local cmd = string.format('git checkout -b %s', branch_name)
  vim.notify('Creating and checking out branch: ' .. branch_name, vim.log.levels.INFO)

  local handle = io.popen(cmd .. ' 2>&1')
  if not handle then
    vim.notify('Failed to create branch', vim.log.levels.ERROR)
    return
  end

  local output = handle:read '*a'

  -- handle:close() returns: true on success, or nil, "exit", exit_code on failure
  -- We need to check explicitly for true to ensure success
  local ok, exit_type, exit_code = handle:close()

  -- Check if the command succeeded (ok == true or exit_code == 0)
  local success = (ok == true) or (exit_type == 'exit' and exit_code == 0)

  local error_message = output:find 'fatal:' or output:find 'Schwerwiegend'

  if success and not error_message then
    vim.notify('✓ Branch created and checked out: ' .. branch_name, vim.log.levels.INFO)
    -- Refresh git status in any open git plugins
    vim.cmd 'checktime'
  else
    local error_msg = 'Failed to create branch'
    if exit_code then
      error_msg = error_msg .. ' (exit code: ' .. exit_code .. ')'
    end
    if output and output ~= '' then
      error_msg = error_msg .. ':\n' .. output
    end
    vim.notify(error_msg, vim.log.levels.ERROR)
  end
end

-- Main function to create branch from Jira ticket
function M.create_branch_from_jira()
  -- Fetch tickets
  local tickets = fetch_jira_tickets()
  if not tickets or #tickets == 0 then
    return
  end

  -- Use Telescope to pick a ticket
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'Select Jira Ticket',
      finder = finders.new_table {
        results = tickets,
        entry_maker = function(entry)
          return {
            value = entry.key,
            display = entry.display,
            ordinal = entry.display,
            ticket = entry,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if not selection then
            return
          end

          local ticket_key = selection.value
          local ticket_summary = selection.ticket.summary

          -- Prompt for branch name
          vim.ui.input({
            prompt = 'Enter branch description (empty to use ticket summary): ',
            default = '',
          }, function(branch_description)
            -- Always create branch, using ticket summary if description is empty
            create_git_branch(ticket_key, branch_description, ticket_summary)
          end)
        end)
        return true
      end,
    })
    :find()
end

-- Store module in package.loaded so it can be required
package.loaded['custom.plugins.jira-branch-module'] = M

-- Lazy.nvim plugin spec
return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    {
      '<leader>gt',
      function()
        require('custom.plugins.jira-branch-module').create_branch_from_jira()
      end,
      desc = '[G]it: New branch from Jira [T]icket',
    },
  },
}
