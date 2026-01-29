---@module "codecompanion"

---@type CodeCompanion
local function try_focus_chat_float()
  -- Focus window if already open (we search for a floating window with specifix zindex)
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    local conf = vim.api.nvim_win_get_config(win_id)
    if conf.focusable and conf.relative ~= '' and conf.zindex == 45 then
      vim.api.nvim_set_current_win(win_id)
      return true
    end
  end
  return false
end

local function focus_or_toggle_chat()
  if try_focus_chat_float() then
    return
  end
  codecompanion.toggle()
  vim.defer_fn(function()
    codecompanion.toggle()
    vim.cmd.startinsert()
  end, 1)
end

-- Globals
-- function VimRc.CodeCompanionConfig.add_context(files)
--   local chat = VimRc.codecompanion.last_chat() or VimRc.codecompanion.chat()
--   if not chat then
--     VimRc.warn 'Could not get cc chat '
--     return
--   end
--   for _, file in ipairs(files) do
--     local f = io.open(file, 'r')
--     local content
--     if f then
--       content = f:read '*a'
--       f:close()
--     end
--     if not content then
--       VimRc.err('Could not read file: ' .. file)
--     else
--       chat:add_context({
--         role = 'user',
--         content = string.format('Here is the content of %s:%s', file, content),
--       }, 'file', string.format('<file>%s</file>', vim.fs.basename(file)))
--     end
--   end
--   focus_or_toggle_chat()
-- end
-- function VimRc.CodeCompanionConfig.run_slash_command(name, cmd_opts)
--   cmd_opts = cmd_opts or {}
--   local chat = VimRc.codecompanion.last_chat() or VimRc.codecompanion.chat()
--   if not chat then
--     VimRc.warn 'Could not get cc chat '
--     return
--   end
--   local cmd = config.strategies.chat.slash_commands[name]
--   if cmd and type(cmd.callback) == 'function' then
--     cmd.callback(chat, cmd_opts)
--     focus_or_toggle_chat()
--   else
--     vim.notify('Slash command not found: ' .. tostring(name), vim.log.levels.ERROR)
--   end
-- end
-- Add options and functionality for each of the opts
-- Finally call the setup function
