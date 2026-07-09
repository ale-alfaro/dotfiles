-- llama.lua — Neovim 0.12 Lua port of autoload/llama.vim
--
-- Conversion notes:
--   * Neovim-only: the classic-Vim textprop / job_start / job_getchannel branches
--     are gone. Everything is extmarks + vim.system().
--   * curl is still the transport (driven by vim.system, which the 0.12 docs use in
--     their own examples). vim.net.request() would be more "native" but I found no
--     streaming-POST support, and the instruct feature streams tokens — so curl stays.
--   * vim.system stdout/on_exit callbacks run in a fast (libuv) context, so anything
--     touching the buffer or extmarks is wrapped in vim.schedule().
--   * SSE stream lines are buffered explicitly (chunks are not line-aligned). This is
--     slightly more correct than the original, which leaned on jobstart's line splitting.
--   * The debug helpers delegated to a llama_debug.vim that wasn't provided, so this
--     ships a small self-contained reimplementation instead.

local api = vim.api
local fn = vim.fn

local M = {}

-- the FIM separator used when hashing prefix/middle/suffix. must be identical
-- everywhere a hash is computed, so it lives in one place.
local SEP = 'Î'

-- =====================================
-- Config
-- =====================================

local default_config = {
  endpoint_fim           = 'http://127.0.0.1:8012/infill',
  endpoint_inst          = 'http://127.0.0.1:8012/v1/chat/completions',
  model_fim              = '',
  model_inst             = '',
  api_key                = '',
  n_prefix               = 256,
  n_suffix               = 64,
  n_predict              = 128,
  stop_strings_fim       = {},
  stop_strings_inst      = {},
  n_cmpl                 = 1,
  t_max_prompt_ms        = 500,
  t_max_predict_ms       = 1000,
  show_info              = 2,
  auto_fim               = true,
  max_line_suffix        = 8,
  max_cache_keys         = 250,
  ring_n_chunks          = 16,
  ring_chunk_size        = 64,
  ring_scope             = 1024,
  ring_update_ms         = 1000,
  keymap_fim_trigger     = '<leader>llf',
  keymap_fim_accept_full = '<Tab>',
  keymap_fim_accept_line = '<S-Tab>',
  keymap_fim_accept_word = '<leader>ll]',
  keymap_fim_next        = '<C-J>',
  keymap_fim_prev        = '<C-K>',
  keymap_inst_trigger    = '<leader>lli',
  keymap_inst_rerun      = '<leader>llr',
  keymap_inst_continue   = '<leader>llc',
  keymap_inst_accept     = '<Tab>',
  keymap_inst_cancel     = '<Esc>',
  keymap_debug_toggle    = '<leader>lld',
  enable_at_startup      = true,
}

-- deprecated key -> current key
local renames = {
  endpoint           = 'endpoint_fim',
  model              = 'model_fim',
  keymap_trigger     = 'keymap_fim_trigger',
  keymap_accept_full = 'keymap_fim_accept_full',
  keymap_accept_line = 'keymap_fim_accept_line',
  keymap_accept_word = 'keymap_fim_accept_word',
  keymap_debug       = 'keymap_debug_toggle',
  stop_strings       = 'stop_strings_fim',
}

-- merged config, populated by build_config()
local config = vim.deepcopy(default_config)

local function build_config()
  local user = vim.deepcopy(vim.g.llama_config or {})

  for old_key, new_key in pairs(renames) do
    if user[old_key] ~= nil then
      user[new_key] = user[old_key]
      user[old_key] = nil
      vim.notify(
        ('llama.vim: %s is deprecated, use %s instead'):format(old_key, new_key),
        vim.log.levels.WARN)
    end
  end

  config = vim.tbl_deep_extend('force', default_config, user)
  vim.g.llama_config = config
end

-- =====================================
-- Small utilities
-- =====================================

-- vim's get(dict, key, default): 0 and false are valid values, so guard on nil.
local function get(t, key, default)
  if t == nil then return default end
  local v = t[key]
  if v == nil then return default end
  return v
end

-- 1-indexed inclusive list slice (avoids ambiguity around vim.list_slice's bounds).
local function sublist(list, i, j)
  local r = {}
  j = j or #list
  for k = i, j do r[#r + 1] = list[k] end
  return r
end

local function list_remove_value(list, val)
  for i = #list, 1, -1 do
    if list[i] == val then table.remove(list, i) end
  end
end

-- number of leading-whitespace columns, expanding tabs to 'tabstop'
local function get_indent(str)
  local n = 0
  for i = 1, #str do
    local c = str:sub(i, i)
    if c == '\t' then
      n = n + vim.bo.tabstop
    elseif c == ' ' then
      n = n + 1
    else
      break
    end
  end
  return n
end

-- inclusive random int in [i0, i1]
local function rand(i0, i1)
  if i1 < i0 then i1 = i0 end
  return math.random(i0, i1)
end

-- word tokens (vim \w includes underscore, so use [%w_])
local function tokenize(lines)
  local toks = {}
  for _, line in ipairs(lines) do
    for tok in line:gmatch('[%w_]+') do
      toks[#toks + 1] = tok
    end
  end
  return toks
end

-- Dice-style similarity of two chunks (lists of lines): 0 = none, 1 = high
local function chunk_sim(c0, c1)
  local t0 = tokenize(c0)
  local t1 = tokenize(c1)

  local set0 = {}
  for _, tok in ipairs(t0) do set0[tok] = true end

  local common = 0
  for _, tok in ipairs(t1) do
    if set0[tok] then common = common + 1 end
  end

  if (#t0 + #t1) == 0 then return 1.0 end
  return 2.0 * common / (#t0 + #t1)
end

-- =====================================
-- Debug helpers (minimal self-contained reimplementation)
-- =====================================

local debug_log_lines = {}
local debug_bufnr = nil

function M.debug_log(msg, ...)
  local extra = { ... }
  local line = tostring(msg)
  if #extra > 0 then
    line = line .. ' | ' .. table.concat(vim.tbl_map(tostring, extra), ' | ')
  end
  debug_log_lines[#debug_log_lines + 1] = os.date('%H:%M:%S ') .. line
  if debug_bufnr and api.nvim_buf_is_valid(debug_bufnr) then
    vim.schedule(function()
      if debug_bufnr and api.nvim_buf_is_valid(debug_bufnr) then
        api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, vim.split(line, '\n', { plain = true }))
      end
    end)
  end
end

function M.debug_clear()
  debug_log_lines = {}
  if debug_bufnr and api.nvim_buf_is_valid(debug_bufnr) then
    api.nvim_buf_set_lines(debug_bufnr, 0, -1, false, {})
  end
end

function M.debug_toggle()
  if debug_bufnr and api.nvim_buf_is_valid(debug_bufnr) then
    local win = fn.bufwinid(debug_bufnr)
    if win ~= -1 then
      api.nvim_win_close(win, true)
      return
    end
  else
    debug_bufnr = api.nvim_create_buf(false, true)
    vim.bo[debug_bufnr].bufhidden = 'hide'
    api.nvim_buf_set_lines(debug_bufnr, 0, -1, false, debug_log_lines)
  end
  vim.cmd('botright split')
  api.nvim_win_set_buf(0, debug_bufnr)
end

function M.debug_setup() end

-- =====================================
-- Highlights
-- =====================================

local function setup_highlights()
  local set = function(name, opts)
    opts.default = true
    api.nvim_set_hl(0, name, opts)
  end
  set('llama_hl_fim_hint',        { fg = '#ff772f', ctermfg = 202 })
  set('llama_hl_fim_info',        { fg = '#77ff2f', ctermfg = 119 })
  set('llama_hl_inst_src',        { bg = '#554433', ctermbg = 236 })
  set('llama_hl_inst_virt_proc',  { fg = '#77ff2f', ctermfg = 119 })
  set('llama_hl_inst_virt_gen',   { fg = '#77ff2f', ctermfg = 119 })
  set('llama_hl_inst_virt_ready', { fg = '#ff772f', ctermfg = 202 })
  set('llama_hl_inst_info',       { link = 'Comment' })
end

-- =====================================
-- Curl transport
-- =====================================

-- build the POST curl command for a JSON endpoint
local function curl_cmd(url)
  local cmd = {
    'curl', '--silent', '--no-buffer',
    '--request', 'POST',
    '--url', url,
    '--header', 'Content-Type: application/json',
    '--data', '@-',
  }
  if config.api_key and config.api_key ~= '' then
    cmd[#cmd + 1] = '--header'
    cmd[#cmd + 1] = 'Authorization: Bearer ' .. config.api_key
  end
  return cmd
end

-- =====================================
-- Module state
-- =====================================

local enabled = false

local ns_fim  = api.nvim_create_namespace('vt_fim')
local ns_inst = api.nvim_create_namespace('vt_inst')

-- cache: key -> ring buffer (list) of response objects, plus an LRU key order
local cache_data = {}
local cache_lru_order = {}

local ring_chunks = {}  -- current set of chunks used as extra context
local ring_queued = {}  -- chunks queued to be sent for processing
local ring_n_evict = 0

local fim_hint_shown = false
local fim_data = {}
local pos_y_pick = -9999
local indent_last = -1

local timer_fim = nil
local t_last_move = fn.reltime()

local current_job_fim = nil

local inst_reqs = {}
local inst_req_id = 0

-- forward declarations (mutual recursion between FIM helpers)
local pick_chunk, ring_update, ring_get_extra, ring_get_extra_text
local fim_try_hint, fim_render, on_move
local inst_send, inst_update, inst_update_pos, inst_remove, inst_callback

-- =====================================
-- Cache (ring buffer per key + LRU eviction)
-- =====================================

local function cache_insert(key, response)
  -- evict LRU key if we're at capacity and this is a new key
  if cache_data[key] == nil and vim.tbl_count(cache_data) >= config.max_cache_keys then
    local lru_key = cache_lru_order[1]
    if lru_key ~= nil then
      cache_data[lru_key] = nil
      table.remove(cache_lru_order, 1)
    end
  end

  if cache_data[key] == nil then
    cache_data[key] = {}
  end

  -- skip if a completion with the same content already exists for this key
  local new_content = get(response, 'content', '')
  for _, existing in ipairs(cache_data[key]) do
    if get(existing, 'content', '') == new_content then
      return
    end
  end

  -- ring buffer: evict oldest if full
  if #cache_data[key] >= config.n_cmpl then
    table.remove(cache_data[key], 1)
  end
  cache_data[key][#cache_data[key] + 1] = response

  list_remove_value(cache_lru_order, key)
  cache_lru_order[#cache_lru_order + 1] = key
end

local function cache_get(key)
  if cache_data[key] == nil then
    return nil
  end
  list_remove_value(cache_lru_order, key)
  cache_lru_order[#cache_lru_order + 1] = key
  return cache_data[key]
end

local function cache_count()
  local total = 0
  for _, entries in pairs(cache_data) do
    total = total + #entries
  end
  return total
end

-- =====================================
-- Enable / disable / toggle
-- =====================================

-- gather the region of lines around the cursor (used by several autocmds)
local function around_lines()
  local half = math.floor(config.ring_chunk_size / 2)
  local cur = fn.line('.')
  local a = math.max(1, cur - half)
  local b = math.min(cur + half, fn.line('$'))
  return fn.getline(a, b)
end

local function setup_autocmds()
  local group = api.nvim_create_augroup('llama', { clear = true })

  -- the FIM trigger is a buffer-local insert-mode expr map installed on InsertEnter
  if config.keymap_fim_trigger ~= '' then
    api.nvim_create_autocmd('InsertEnter', { group = group, callback = function()
      vim.keymap.set('i', config.keymap_fim_trigger, function()
        return M.fim_inline(false, false)
      end, { buffer = true, expr = true, silent = true })
    end })
  end

  api.nvim_create_autocmd('InsertLeavePre', { group = group, callback = function() M.fim_hide() end })
  api.nvim_create_autocmd('CompleteChanged', { group = group, callback = function() M.fim_hide() end })
  api.nvim_create_autocmd('CompleteDone',    { group = group, callback = function() on_move() end })

  if config.auto_fim then
    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { group = group, callback = function() on_move() end })
    api.nvim_create_autocmd('CursorMovedI', { group = group, callback = function()
      M.fim(-1, -1, true, {}, true)
    end })
  end

  -- gather chunks upon yanking
  api.nvim_create_autocmd('TextYankPost', { group = group, callback = function()
    if vim.v.event.operator == 'y' then
      pick_chunk(vim.v.event.regcontents, false, true)
    end
  end })

  -- gather chunks upon entering / leaving a buffer
  api.nvim_create_autocmd('BufEnter', { group = group, callback = function()
    vim.defer_fn(function() pick_chunk(around_lines(), true, true) end, 100)
  end })
  api.nvim_create_autocmd('BufLeave', { group = group, callback = function()
    pick_chunk(around_lines(), true, true)
  end })

  -- gather a chunk upon saving the file
  api.nvim_create_autocmd('BufWritePost', { group = group, callback = function()
    pick_chunk(around_lines(), true, true)
  end })
end

-- try to delete a keymap, ignoring "not found"
local function del_keymap(mode, lhs, opts)
  if lhs == nil or lhs == '' then return end
  pcall(vim.keymap.del, mode, lhs, opts or {})
end

function M.disable()
  M.fim_hide()

  pcall(api.nvim_del_augroup_by_name, 'llama')

  del_keymap('i', config.keymap_fim_trigger, { buffer = true })
  del_keymap('i', config.keymap_fim_accept_full, { buffer = true })
  del_keymap('i', config.keymap_fim_accept_line, { buffer = true })
  del_keymap('i', config.keymap_fim_accept_word, { buffer = true })
  del_keymap('i', config.keymap_fim_next, { buffer = true })
  del_keymap('i', config.keymap_fim_prev, { buffer = true })

  del_keymap('n', config.keymap_debug_toggle)
  del_keymap('v', config.keymap_inst_trigger)
  del_keymap('n', config.keymap_inst_rerun)
  del_keymap('n', config.keymap_inst_continue)
  del_keymap('n', config.keymap_inst_accept)
  del_keymap('n', config.keymap_inst_cancel)

  enabled = false
  M.debug_log('plugin disabled')
end

function M.enable()
  if enabled then return end

  if config.keymap_debug_toggle ~= '' then
    vim.keymap.set('n', config.keymap_debug_toggle, M.debug_toggle, { silent = true })
  end
  if config.keymap_inst_trigger ~= '' then
    vim.keymap.set('v', config.keymap_inst_trigger, ':LlamaInstruct<CR>', { silent = true })
  end
  if config.keymap_inst_rerun ~= '' then
    vim.keymap.set('n', config.keymap_inst_rerun, M.inst_rerun, { silent = true })
  end
  if config.keymap_inst_continue ~= '' then
    vim.keymap.set('n', config.keymap_inst_continue, M.inst_continue, { silent = true })
  end
  if config.keymap_inst_accept ~= '' then
    vim.keymap.set('n', config.keymap_inst_accept, M.inst_accept, { silent = true })
  end
  if config.keymap_inst_cancel ~= '' then
    vim.keymap.set('n', config.keymap_inst_cancel, M.inst_cancel, { silent = true })
  end

  setup_autocmds()
  M.fim_hide()

  -- init background update of the ring buffer
  if config.ring_n_chunks > 0 then
    ring_update()
  end

  enabled = true
  M.debug_log('plugin enabled')
end

function M.toggle()
  if enabled then M.disable() else M.enable() end
end

function M.toggle_auto_fim()
  if not enabled then return end
  config.auto_fim = not config.auto_fim
  setup_autocmds()
end

-- =====================================
-- Status (query loaded models on /v1/models)
-- =====================================

local status_messages = { fim = '', inst = '', count = 0 }

local function get_model_status(model_name, models)
  if model_name == nil or model_name == '' then
    return '❌ Not configured'
  end

  local function status_of(model)
    if model.status ~= nil then
      local sv = get(model.status, 'value', 'unknown')
      return sv == 'loaded' and '✅ Ready' or sv
    end
    return '✅ Ready'
  end

  for _, model in ipairs(models) do
    if get(model, 'id', '') == model_name
        or vim.tbl_contains(get(model, 'tags', {}), model_name)
        or vim.tbl_contains(get(model, 'aliases', {}), model_name) then
      return status_of(model)
    end
  end

  if #models == 1 then
    return status_of(models[1])
  end

  return '❌ Not loaded'
end

local function display_status_if_ready()
  if status_messages.count >= 2 then
    api.nvim_echo({ { status_messages.fim .. ', ' .. status_messages.inst } }, false, {})
  end
end

local function fetch_status(url, kind)
  local cmd = { 'curl', '--silent', '--max-time', '3', '--request', 'GET', '--url', url }

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        M.debug_log('status: curl failed (' .. kind .. ') code ' .. obj.code)
        if kind == 'both' then
          api.nvim_echo({ { 'LlamaStatus: ❌ Server not reachable' } }, false, {})
        elseif kind == 'fim' then
          status_messages.fim = 'FIM server: ❌ Not reachable'
          status_messages.count = status_messages.count + 1
          display_status_if_ready()
        elseif kind == 'inst' then
          status_messages.inst = 'Instruction server: ❌ Not reachable'
          status_messages.count = status_messages.count + 1
          display_status_if_ready()
        end
        return
      end

      local ok, response = pcall(vim.json.decode, obj.stdout or '')
      if not ok or type(response) ~= 'table' then return end
      local models = get(response, 'data', {})

      if kind == 'both' then
        local fim_status = get_model_status(config.model_fim, models)
        local inst_status = get_model_status(config.model_inst, models)
        api.nvim_echo({ {
          ('FIM model (%s): %s, Instruction model (%s): %s')
            :format(config.model_fim, fim_status, config.model_inst, inst_status)
        } }, false, {})
      elseif kind == 'fim' then
        status_messages.fim = 'FIM model (' .. config.model_fim .. '): ' .. get_model_status(config.model_fim, models)
        status_messages.count = status_messages.count + 1
        display_status_if_ready()
      elseif kind == 'inst' then
        status_messages.inst = 'Instruction model (' .. config.model_inst .. '): ' .. get_model_status(config.model_inst, models)
        status_messages.count = status_messages.count + 1
        display_status_if_ready()
      end
    end)
  end)
end

function M.status()
  local fim_base  = (config.endpoint_fim:gsub('/infill$', ''))
  local inst_base = (config.endpoint_inst:gsub('/v1/chat/completions$', ''))

  status_messages = { fim = '', inst = '', count = 0 }

  -- same base => single router server, otherwise two independent servers
  if fim_base == inst_base then
    fetch_status(fim_base .. '/v1/models', 'both')
  else
    fetch_status(fim_base .. '/v1/models', 'fim')
    fetch_status(inst_base .. '/v1/models', 'inst')
  end
end

-- =====================================
-- Ring buffer of extra context
-- =====================================

-- pick a random chunk of size ring_chunk_size from text and queue it
--   no_mod   - skip buffers with pending changes / non-file buffers
--   do_evict - evict queued/ring chunks very similar to this one
function pick_chunk(text, no_mod, do_evict)
  if no_mod then
    local buf = api.nvim_get_current_buf()
    if vim.bo[buf].modified or fn.buflisted(buf) == 0 or fn.filereadable(fn.expand('%')) == 0 then
      return
    end
  end

  if config.ring_n_chunks <= 0 then return end
  if #text < 3 then return end

  local half = math.floor(config.ring_chunk_size / 2)
  local chunk
  if #text + 1 < config.ring_chunk_size then
    chunk = text
  else
    local l0 = rand(0, math.max(0, #text - half))
    local l1 = math.min(l0 + half, #text)
    chunk = sublist(text, l0 + 1, l1 + 1)
  end

  local chunk_str = table.concat(chunk, '\n') .. '\n'

  -- already present?
  for _, c in ipairs(ring_chunks) do
    if vim.deep_equal(c.data, chunk) then return end
  end
  for _, c in ipairs(ring_queued) do
    if vim.deep_equal(c.data, chunk) then return end
  end

  -- evict queued chunks very similar to the new one
  for i = #ring_queued, 1, -1 do
    if chunk_sim(ring_queued[i].data, chunk) > 0.9 then
      if do_evict then
        table.remove(ring_queued, i)
        ring_n_evict = ring_n_evict + 1
      else
        return
      end
    end
  end
  -- ... and from ring_chunks
  for i = #ring_chunks, 1, -1 do
    if chunk_sim(ring_chunks[i].data, chunk) > 0.9 then
      if do_evict then
        table.remove(ring_chunks, i)
        ring_n_evict = ring_n_evict + 1
      else
        return
      end
    end
  end

  if #ring_queued == 16 then
    table.remove(ring_queued, 1)
  end

  ring_queued[#ring_queued + 1] = {
    data = chunk,
    str = chunk_str,
    time = fn.reltime(),
    filename = fn.expand('%'),
  }
end

function ring_get_extra()
  local extra = {}
  for _, chunk in ipairs(ring_chunks) do
    extra[#extra + 1] = { text = chunk.str, time = chunk.time, filename = chunk.filename }
  end
  return extra
end

-- move a queued chunk into the ring and warm the server cache with it.
-- re-arms itself every ring_update_ms.
function ring_update()
  vim.defer_fn(ring_update, config.ring_update_ms)

  -- skip if we're not in normal mode and the cursor moved recently
  if fn.mode() ~= 'n' and fn.reltimefloat(fn.reltime(t_last_move)) < 3.0 then
    return
  end

  if #ring_queued == 0 then return end

  if #ring_chunks == config.ring_n_chunks then
    table.remove(ring_chunks, 1)
  end
  ring_chunks[#ring_chunks + 1] = table.remove(ring_queued, 1)

  local extra = ring_get_extra()

  local request = {
    id_slot          = 0,
    input_prefix     = '',
    input_suffix     = '',
    input_extra      = extra,
    prompt           = '',
    n_predict        = 0,
    temperature      = 0.0,
    samplers         = {},
    stream           = false,
    cache_prompt     = true,
    t_max_prompt_ms  = 1,
    t_max_predict_ms = 1,
    response_fields  = { '' },
  }
  if config.model_fim ~= '' then request.model = config.model_fim end

  -- fire-and-forget: we don't process the response
  vim.system(curl_cmd(config.endpoint_fim), { stdin = vim.json.encode(request), text = true })
end

-- =====================================
-- Fill-in-Middle (FIM) completion
-- =====================================

-- local context around (pos_x, pos_y); a:prev may hold a previous completion,
-- in which case we build the context as if it had already been inserted.
local function fim_ctx_local(pos_x, pos_y, prev)
  local max_y = fn.line('$')

  local line_cur, line_cur_prefix, line_cur_suffix, lines_prefix, lines_suffix, indent

  if prev == nil or #prev == 0 then
    line_cur = fn.getline(pos_y)
    line_cur_prefix = line_cur:sub(1, pos_x)
    line_cur_suffix = line_cur:sub(pos_x + 1)

    lines_prefix = fn.getline(math.max(1, pos_y - config.n_prefix), pos_y - 1)
    lines_suffix = fn.getline(pos_y + 1, math.min(max_y, pos_y + config.n_suffix))

    if line_cur:match('^%s*$') then
      indent = 0
      line_cur_prefix = ''
      line_cur_suffix = ''
    else
      indent = #(line_cur:match('^%s*') or '')
    end
  else
    if #prev == 1 then
      line_cur = fn.getline(pos_y) .. prev[1]
    else
      line_cur = prev[#prev]
    end

    line_cur_prefix = line_cur
    line_cur_suffix = ''

    lines_prefix = fn.getline(math.max(1, pos_y - config.n_prefix + #prev - 1), pos_y - 1)
    if #prev > 1 then
      lines_prefix[#lines_prefix + 1] = fn.getline(pos_y) .. prev[1]
      for _, line in ipairs(sublist(prev, 2, #prev - 1)) do
        lines_prefix[#lines_prefix + 1] = line
      end
    end

    lines_suffix = fn.getline(pos_y + 1, math.min(max_y, pos_y + config.n_suffix))
    indent = indent_last
  end

  local prefix = table.concat(lines_prefix, '\n') .. '\n'
  local middle = line_cur_prefix
  local suffix = line_cur_suffix .. '\n' .. table.concat(lines_suffix, '\n') .. '\n'

  return {
    prefix = prefix,
    middle = middle,
    suffix = suffix,
    indent = indent,
    line_cur = line_cur,
    line_cur_prefix = line_cur_prefix,
    line_cur_suffix = line_cur_suffix,
  }
end

-- for expr keymap: toggle-or-request
function M.fim_inline(is_auto, use_cache)
  if not enabled then return '' end
  if fim_hint_shown and not is_auto then
    M.fim_hide()
    return ''
  end
  M.fim(-1, -1, is_auto, {}, use_cache)
  return ''
end

-- callback that processes the FIM result from the server
local function fim_on_response(hashes, obj)
  local raw = obj.stdout or ''
  if #raw == 0 then return end

  -- fast structural check before decoding
  if (not raw:match('^%s*{') and not raw:match('^%s*%[')) or not raw:match('"content"%s*:"') then
    return
  end
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok then return end

  -- normalize to a list of response objects
  local responses
  if vim.islist(decoded) then
    responses = decoded
  else
    responses = { decoded }
  end

  for _, hash in ipairs(hashes) do
    for _, resp in ipairs(responses) do
      cache_insert(hash, resp)
    end
  end

  -- if nothing is currently displayed, show the hint directly
  if not fim_hint_shown or not fim_data.can_accept then
    M.debug_log('fim_on_response', get(responses[1], 'content', ''))
    fim_try_hint(fn.col('.') - 1, fn.line('.'))
  end
end

-- the main FIM call: take local + extra context and request a completion
function M.fim(pos_x, pos_y, is_auto, prev, use_cache)
  pos_x = pos_x >= 0 and pos_x or (fn.col('.') - 1)
  pos_y = pos_y >= 0 and pos_y or fn.line('.')
  prev = prev or {}

  -- throttle: if a request is in flight, retry shortly
  if current_job_fim ~= nil then
    if timer_fim ~= nil then
      pcall(function() timer_fim:stop() end)
      timer_fim = nil
    end
    timer_fim = vim.defer_fn(function()
      M.fim(pos_x, pos_y, true, prev, use_cache)
    end, 100)
    return
  end

  local ctx = fim_ctx_local(pos_x, pos_y, prev)
  local prefix, middle, suffix, indent = ctx.prefix, ctx.middle, ctx.suffix, ctx.indent

  if is_auto and #ctx.line_cur_suffix > config.max_line_suffix then
    return
  end

  local t_max_predict_ms = config.t_max_predict_ms
  if #prev == 0 then
    -- first request is quick; a speculative one follows once it's displayed
    t_max_predict_ms = 250
  end

  -- hashes that also match when the first lines have scrolled out of view
  local hashes = { fn.sha256(prefix .. middle .. SEP .. suffix) }
  local prefix_trim = prefix
  for _ = 1, 3 do
    prefix_trim = (prefix_trim:gsub('^[^\n]*\n', '', 1))
    if prefix_trim == '' then break end
    hashes[#hashes + 1] = fn.sha256(prefix_trim .. middle .. SEP .. suffix)
  end

  -- skip the request if we already have a cached completion for one of them
  if use_cache then
    for _, hash in ipairs(hashes) do
      local cached = cache_get(hash)
      if cached ~= nil and #cached > 0 then
        return
      end
    end
  end

  indent_last = indent

  -- evict ring chunks very similar to the current context (they distort output)
  local half = math.floor(config.ring_chunk_size / 2)
  local text = fn.getline(math.max(1, fn.line('.') - half), math.min(fn.line('.') + half, fn.line('$')))
  local l0 = rand(0, math.max(0, #text - half))
  local l1 = math.min(l0 + half, #text)
  local chunk = sublist(text, l0 + 1, l1 + 1)
  for i = #ring_chunks, 1, -1 do
    if chunk_sim(ring_chunks[i].data, chunk) > 0.5 then
      table.remove(ring_chunks, i)
      ring_n_evict = ring_n_evict + 1
    end
  end

  local extra = ring_get_extra()

  local request = {
    id_slot          = 0,
    input_prefix     = prefix,
    input_suffix     = suffix,
    input_extra      = extra,
    prompt           = middle,
    n_predict        = config.n_predict,
    stop             = config.stop_strings_fim,
    n_cmpl           = config.n_cmpl,
    n_indent         = indent,
    top_k            = 40,
    top_p            = 0.90,
    samplers         = { 'top_k', 'top_p', 'infill' },
    stream           = false,
    cache_prompt     = true,
    t_max_prompt_ms  = config.t_max_prompt_ms,
    t_max_predict_ms = t_max_predict_ms,
    response_fields  = {
      'content',
      'timings/prompt_n', 'timings/prompt_ms', 'timings/prompt_per_token_ms', 'timings/prompt_per_second',
      'timings/predicted_n', 'timings/predicted_ms', 'timings/predicted_per_token_ms', 'timings/predicted_per_second',
      'truncated', 'tokens_cached',
    },
  }
  if config.model_fim ~= '' then request.model = config.model_fim end

  current_job_fim = vim.system(curl_cmd(config.endpoint_fim), {
    stdin = vim.json.encode(request),
    text = true,
  }, function(obj)
    current_job_fim = nil
    if obj.code ~= 0 then
      vim.schedule(function() api.nvim_echo({ { 'FIM job failed with exit code: ' .. obj.code } }, true, {}) end)
      return
    end
    vim.schedule(function() fim_on_response(hashes, obj) end)
  end)

  -- gather extra context nearby only when the cursor has moved a lot
  local delta_y = math.abs(pos_y - pos_y_pick)
  if is_auto and delta_y > 32 then
    local max_y = fn.line('$')
    -- expand the prefix further back
    pick_chunk(fn.getline(math.max(1, pos_y - config.ring_scope), math.max(1, pos_y - config.n_prefix)), false, false)
    -- pick a suffix chunk
    pick_chunk(fn.getline(math.min(max_y, pos_y + config.n_suffix), math.min(max_y, pos_y + config.n_suffix + config.ring_chunk_size)), false, false)
    pos_y_pick = pos_y
  end
end

function on_move()
  t_last_move = fn.reltime()
  M.fim_hide()
  fim_try_hint(fn.col('.') - 1, fn.line('.'))
end

-- try to build a suggestion from cached data
function fim_try_hint(pos_x, pos_y)
  -- only show the suggestion in insert / insert-completion / insert-x modes
  local m = fn.mode()
  if m ~= 'i' and m ~= 'ic' and m ~= 'ix' then return end

  local ctx = fim_ctx_local(pos_x, pos_y, {})
  local prefix, middle, suffix = ctx.prefix, ctx.middle, ctx.suffix

  -- Phase 1: exact match at the current position (supports cycling)
  local hash = fn.sha256(prefix .. middle .. SEP .. suffix)
  local responses = cache_get(hash)
  if responses ~= nil and #responses > 0 then
    fim_render(pos_x, pos_y, responses, 0)
    if fim_hint_shown then
      M.fim(pos_x, pos_y, true, fim_data.content, true)
    end
    return
  end

  -- Phase 2: nearby match — a cached completion whose start matches what was typed.
  -- pick the single best (longest remaining) match; no cycling.
  local pm = prefix .. middle
  local best_len = 0
  local best_resp = nil

  for i = 0, 127 do
    local typed   = pm:sub(-(i + 1))
    local ctx_new = pm:sub(1, #pm - (i + 1)) .. SEP .. suffix
    local cached  = cache_get(fn.sha256(ctx_new))
    if cached ~= nil then
      for _, resp in ipairs(cached) do
        local content = get(resp, 'content', '')
        if #content > i and content:sub(1, i + 1) == typed then
          local remainder = content:sub(i + 2)
          if #remainder > best_len then
            best_len = #remainder
            best_resp = vim.deepcopy(resp)
            best_resp.content = remainder
          end
        end
      end
    end
  end

  if best_resp ~= nil then
    fim_render(pos_x, pos_y, { best_resp }, 0)
    if fim_hint_shown then
      M.fim(pos_x, pos_y, true, fim_data.content, true)
    end
  end
end

-- render a suggestion at the cursor
--   responses - list of response objects
--   selected  - 0-indexed selected completion
function fim_render(pos_x, pos_y, responses, selected)
  if fn.pumvisible() == 1 then return end

  local bufnr = api.nvim_get_current_buf()
  api.nvim_buf_clear_namespace(bufnr, ns_fim, 0, -1)

  local response = responses[selected + 1]

  local can_accept = true
  local n_prompt, t_prompt_ms, s_prompt = 0, 1.0, 0
  local n_predict, t_predict_ms, s_predict = 0, 1.0, 0

  local content = vim.split(get(response, 'content', ''), '\n', { plain = true })

  -- drop trailing empty lines
  while #content > 0 and content[#content] == '' do
    table.remove(content, #content)
  end

  local n_cached  = get(response, 'tokens_cached', 0)
  local truncated = get(response, 'timings/truncated', false)

  if response['timings/prompt_n'] ~= nil and response['timings/prompt_ms'] ~= nil
      and response['timings/prompt_per_second'] ~= nil and response['timings/predicted_n'] ~= nil
      and response['timings/predicted_ms'] ~= nil and response['timings/predicted_per_second'] ~= nil then
    n_prompt     = get(response, 'timings/prompt_n', 0)
    t_prompt_ms  = tonumber(get(response, 'timings/prompt_ms', 1.0)) or 1.0
    s_prompt     = tonumber(get(response, 'timings/prompt_per_second', 0.0)) or 0.0
    n_predict    = get(response, 'timings/predicted_n', 0)
    t_predict_ms = tonumber(get(response, 'timings/predicted_ms', 1.0)) or 1.0
    s_predict    = tonumber(get(response, 'timings/predicted_per_second', 0.0)) or 0.0
  end

  if #content == 0 then
    content = { '' }
    can_accept = false
  end

  local line_cur = fn.getline(pos_y)

  -- if the current line is only whitespace, trim leading ws from the suggestion
  if line_cur:match('^%s*$') then
    local lead = math.min(#(content[1]:match('^%s*') or ''), #line_cur)
    line_cur = content[1]:sub(1, lead)
    content[1] = content[1]:sub(lead + 1)
  end

  local line_cur_prefix = line_cur:sub(1, pos_x)
  local line_cur_suffix = line_cur:sub(pos_x + 1)

  -- discard predictions that just repeat existing text (see original for rationale)
  if #content == 1 and content[1] == '' then
    content = { '' }
  end
  if #content > 1 and content[1] == ''
      and vim.deep_equal(sublist(content, 2), fn.getline(pos_y + 1, pos_y + #content - 1)) then
    content = { '' }
  end
  if #content == 1 and content[1] == line_cur_suffix then
    content = { '' }
  end

  -- find the first non-empty line below
  local cmp_y = pos_y + 1
  while cmp_y < fn.line('$') and fn.getline(cmp_y):match('^%s*$') do
    cmp_y = cmp_y + 1
  end

  if (line_cur_prefix .. content[1]) == fn.getline(cmp_y) then
    if #content == 1 then
      content = { '' }
    end
    if #content == 2 and content[#content] == fn.getline(cmp_y + 1):sub(1, #content[#content]) then
      content = { '' }
    end
    if #content > 2 and table.concat(sublist(content, 2), '\n')
        == table.concat(fn.getline(cmp_y + 1, cmp_y + #content - 1), '\n') then
      content = { '' }
    end
  end

  content[#content] = content[#content] .. line_cur_suffix

  if table.concat(content, '\n'):match('^%s*$') then
    can_accept = false
  end

  -- info line
  local info = ''
  if config.show_info > 0 then
    local prefix_pad = '   '
    local cmpl_idx = ''
    if #responses > 1 then
      cmpl_idx = (' [%d/%d]'):format(selected + 1, #responses)
    end

    if truncated then
      info = ('%s | WARNING: the context is full: %d, increase the server context size or reduce g:llama_config.ring_n_chunks%s'):format(
        config.show_info == 2 and prefix_pad or 'llama.vim', n_cached, cmpl_idx)
    else
      info = ('%s | c: %d, r: %d/%d, e: %d, q: %d/16, C: %d | p: %d (%.2f ms, %.2f t/s) | g: %d (%.2f ms, %.2f t/s)%s'):format(
        config.show_info == 2 and prefix_pad or 'llama.vim',
        n_cached, #ring_chunks, config.ring_n_chunks, ring_n_evict, #ring_queued,
        cache_count(),
        n_prompt, t_prompt_ms, s_prompt,
        n_predict, t_predict_ms, s_predict,
        cmpl_idx)
    end

    if config.show_info == 1 then
      vim.o.statusline = info
      info = ''
    end
  end

  local is_empty = (#content == 1 and content[1] == '')

  api.nvim_buf_set_extmark(bufnr, ns_fim, pos_y - 1, pos_x, {
    virt_text = { { content[1], 'llama_hl_fim_hint' }, { info, 'llama_hl_fim_info' } },
    virt_text_pos = is_empty and 'eol' or 'overlay',
  })

  local virt_lines = {}
  for _, val in ipairs(sublist(content, 2)) do
    virt_lines[#virt_lines + 1] = { { val, 'llama_hl_fim_hint' } }
  end
  api.nvim_buf_set_extmark(bufnr, ns_fim, pos_y - 1, 0, { virt_lines = virt_lines })

  -- accept shortcuts (insert mode, buffer-local). Called as plain callbacks;
  -- unlike the original we don't need <C-O> because these are function calls.
  if config.keymap_fim_accept_full ~= '' then
    vim.keymap.set('i', config.keymap_fim_accept_full, function() M.fim_accept('full') end, { buffer = true })
  end
  if config.keymap_fim_accept_line ~= '' then
    vim.keymap.set('i', config.keymap_fim_accept_line, function() M.fim_accept('line') end, { buffer = true })
  end
  if config.keymap_fim_accept_word ~= '' then
    vim.keymap.set('i', config.keymap_fim_accept_word, function() M.fim_accept('word') end, { buffer = true })
  end

  -- cycle shortcuts (always set, so <C-J>/<C-K> don't move the cursor)
  if config.keymap_fim_next ~= '' then
    vim.keymap.set('i', config.keymap_fim_next, function() return M.fim_cycle(1) end, { buffer = true, expr = true })
  end
  if config.keymap_fim_prev ~= '' then
    vim.keymap.set('i', config.keymap_fim_prev, function() return M.fim_cycle(-1) end, { buffer = true, expr = true })
  end

  fim_hint_shown = true
  fim_data = {
    pos_x = pos_x,
    pos_y = pos_y,
    line_cur = line_cur,
    can_accept = can_accept,
    content = content,
    responses = responses,
    selected = selected,
  }
end

--   'full' - accept the whole response
--   'line' - accept only the first line
--   'word' - accept only the first word
function M.fim_accept(accept_type)
  local pos_x = fim_data.pos_x
  local pos_y = fim_data.pos_y
  local line_cur = fim_data.line_cur
  local can_accept = fim_data.can_accept
  local content = fim_data.content

  if can_accept and #content > 0 then
    if accept_type ~= 'word' then
      fn.setline(pos_y, line_cur:sub(1, pos_x) .. content[1])
    else
      local suffix = line_cur:sub(pos_x + 1)
      local word = (content[1]:sub(1, #content[1] - #suffix)):match('^%s*%S+') or ''
      fn.setline(pos_y, line_cur:sub(1, pos_x) .. word .. suffix)

      if #content > 1 and accept_type == 'full' then
        fn.append(pos_y, sublist(content, 2))
      end
      fn.cursor(pos_y, pos_x + #word + 1)
      M.fim_hide()
      return
    end

    if #content > 1 and accept_type == 'full' then
      fn.append(pos_y, sublist(content, 2))
    end

    if accept_type == 'line' or #content == 1 then
      fn.cursor(pos_y, pos_x + #content[1] + 1)
      if #content > 1 then
        api.nvim_feedkeys(vim.keycode('<CR>'), 'n', false)
      end
    else
      fn.cursor(pos_y + #content - 1, #content[#content] + 1)
    end
  end

  M.fim_hide()
end

function M.fim_hide()
  fim_hint_shown = false

  local bufnr = api.nvim_get_current_buf()
  api.nvim_buf_clear_namespace(bufnr, ns_fim, 0, -1)

  if config.show_info == 1 then
    vim.o.statusline = ''
  end

  del_keymap('i', config.keymap_fim_accept_full, { buffer = true })
  del_keymap('i', config.keymap_fim_accept_line, { buffer = true })
  del_keymap('i', config.keymap_fim_accept_word, { buffer = true })
  del_keymap('i', config.keymap_fim_next, { buffer = true })
  del_keymap('i', config.keymap_fim_prev, { buffer = true })
end

function M.is_fim_hint_shown()
  return fim_hint_shown
end

--   direction - 1 for next, -1 for previous; returns '' for the expr mapping
function M.fim_cycle(direction)
  if not fim_hint_shown then return '' end
  local n = #fim_data.responses
  if n <= 1 then return '' end
  fim_data.selected = (fim_data.selected + direction + n) % n
  fim_render(fim_data.pos_x, fim_data.pos_y, fim_data.responses, fim_data.selected)
  return ''
end

-- =====================================
-- Instruct-based editing
-- =====================================

function M.inst_build(l0, l1, inst, inst_prev)
  local prefix    = fn.getline(math.max(1, l0 - config.n_prefix), l0 - 1)
  local selection = fn.getline(l0, l1)
  local suffix    = fn.getline(l1 + 1, math.min(fn.line('$'), l1 + config.n_suffix))

  local messages
  if inst_prev ~= nil and #inst_prev > 0 then
    messages = vim.deepcopy(inst_prev)
  else
    local sep = string.rep('-', 40)
    local sp = ''
    sp = sp .. 'You are a text-editing assistant. Respond ONLY with the result of applying INSTRUCTION to SELECTION given the CONTEXT. Maintain the existing text indentation. Do not add extra code blocks. Respond only with the modified block. If the INSTRUCTION is a question, answer it directly. Do not output any extra separators. Consider the local context before (PREFIX) and after (SUFFIX) the SELECTION.\n'
    sp = sp .. '\n'
    sp = sp .. '--- CONTEXT     ' .. sep .. '\n' .. table.concat(ring_get_extra_text(), '\n') .. '\n'
    sp = sp .. '--- PREFIX      ' .. sep .. '\n' .. table.concat(prefix, '\n') .. '\n'
    sp = sp .. '--- SELECTION   ' .. sep .. '\n' .. table.concat(selection, '\n') .. '\n'
    sp = sp .. '--- SUFFIX      ' .. sep .. '\n' .. table.concat(suffix, '\n') .. '\n'

    messages = { { role = 'system', content = sp } }
  end

  local user_content = ''
  if inst ~= nil and inst ~= '' then
    user_content = 'INSTRUCTION: ' .. inst
  end
  messages[#messages + 1] = { role = 'user', content = user_content }

  return messages
end

-- the original joined ring_get_extra() (a list of dicts) directly into the prompt,
-- which stringifies each entry. keep just the text, which is what's useful.
function ring_get_extra_text()
  local out = {}
  for _, c in ipairs(ring_chunks) do out[#out + 1] = c.str end
  return out
end

function M.inst(l0, l1)
  local req_id = inst_req_id
  inst_req_id = inst_req_id + 1

  -- warm-up request while the user types the instruction
  do
    local messages = M.inst_build(l0, l1, '')
    local request = {
      id_slot         = req_id,
      messages        = messages,
      samplers        = {},
      n_predict       = 0,
      stream          = false,
      stop            = config.stop_strings_inst,
      cache_prompt    = true,
      response_fields = { '' },
    }
    if config.model_inst ~= '' then request.model = config.model_inst end
    vim.system(curl_cmd(config.endpoint_inst), { stdin = vim.json.encode(request), text = true })
  end

  local inst = fn.input('Instruction: ')
  if inst == '' then return end

  M.debug_log('inst_send | ' .. inst)

  local bufnr = api.nvim_get_current_buf()

  local req = {
    id = req_id,
    bufnr = bufnr,
    range = { l0, l1 },
    status = 'proc',
    result = '',
    inst = inst,
    inst_prev = {},
    job = nil,
    n_gen = 0,
    extmark = -1,
    extmark_virt = -1,
    sse = '',
  }
  inst_reqs[req_id] = req

  -- highlight the selected text
  req.extmark = api.nvim_buf_set_extmark(bufnr, ns_inst, l0 - 1, 0, {
    end_row = l1 - 1,
    end_col = #fn.getline(l1),
    hl_group = 'llama_hl_inst_src',
  })

  inst_update(req_id, 'proc')

  req.inst_prev = M.inst_build(l0, l1, inst)
  M.inst_send(req_id, req.inst_prev)
end

-- parse a single SSE line into the request's accumulating result
local function inst_feed_line(req, line)
  line = line:gsub('\r$', '')
  if line:sub(1, 6) == 'data: ' then
    line = line:sub(7)
  end
  if line == '' or line:match('^%s*$') then return end

  local ok, response = pcall(vim.json.decode, line)
  if not ok then
    M.debug_log('inst_on_response parse error', line)
    return
  end

  local choices = get(response, 'choices', { {} })
  local choice = choices[1] or {}
  local delta

  if choice.delta ~= nil then          -- stream = true
    if type(choice.delta.content) == 'string' then delta = choice.delta.content end
  elseif choice.message ~= nil then    -- stream = false
    if type(choice.message.content) == 'string' then delta = choice.message.content end
  end

  if delta and delta ~= '' then
    req.result = req.result .. delta
    req.n_gen = req.n_gen + 1
  end
end

function M.inst_send(req_id, messages)
  M.debug_log('inst_send', table.concat(vim.tbl_map(function(m) return m.content or '' end, messages), '\n'))

  local request = {
    id_slot      = req_id,
    messages     = messages,
    min_p        = 0.1,
    temperature  = 0.1,
    samplers     = { 'min_p', 'temperature' },
    stop         = config.stop_strings_inst,
    stream       = true,
    cache_prompt = true,
  }
  if config.model_inst ~= '' then request.model = config.model_inst end

  local req = inst_reqs[req_id]
  req.sse = ''

  req.job = vim.system(curl_cmd(config.endpoint_inst), {
    stdin = vim.json.encode(request),
    text = true,
    stdout = function(err, data)
      if err or not data then return end
      -- parse in the fast context (pure Lua), then schedule the UI update
      req.sse = req.sse .. data
      while true do
        local nl = req.sse:find('\n')
        if not nl then break end
        local line = req.sse:sub(1, nl - 1)
        req.sse = req.sse:sub(nl + 1)
        inst_feed_line(req, line)
      end
      if inst_reqs[req_id] ~= nil then
        vim.schedule(function() inst_update(req_id, 'gen') end)
      end
    end,
  }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        api.nvim_echo({ { 'Instruct job failed with exit code: ' .. obj.code } }, true, {})
        inst_remove(req_id)
        return
      end
      if inst_reqs[req_id] == nil then return end
      inst_update(req_id, 'ready')
      -- record the assistant turn for continuation
      inst_reqs[req_id].inst_prev[#inst_reqs[req_id].inst_prev + 1] =
        { role = 'assistant', content = inst_reqs[req_id].result }
    end)
  end)
end

function inst_update_pos(req)
  local pos = api.nvim_buf_get_extmark_by_id(req.bufnr, ns_inst, req.extmark, {})
  if not pos or #pos == 0 then return end
  local line = pos[1] + 1
  req.range[2] = line + (req.range[2] - req.range[1])
  req.range[1] = line
end

function inst_update(id, status)
  local req = inst_reqs[id]
  if req == nil then return end

  req.status = status
  inst_update_pos(req)

  if req.extmark_virt ~= -1 then
    api.nvim_buf_del_extmark(req.bufnr, ns_inst, req.extmark_virt)
    req.extmark_virt = -1
  end

  local inst_trunc = req.inst
  if #inst_trunc > 128 then
    inst_trunc = inst_trunc:sub(1, 128) .. '...'
  end

  local sep = '====================================='
  local hl, virt_lines = '', {}

  if status == 'ready' then
    hl = 'llama_hl_inst_virt_ready'
    virt_lines = { { { sep, hl } } }
    for _, val in ipairs(vim.split(req.result, '\n', { plain = true })) do
      virt_lines[#virt_lines + 1] = { { val, hl } }
    end
  elseif status == 'proc' then
    hl = 'llama_hl_inst_virt_proc'
    virt_lines = {
      { { sep, hl } },
      { { ('Endpoint:    %s'):format(config.endpoint_inst), hl } },
      { { ('Model:       %s'):format(config.model_inst), hl } },
      { { ('Instruction: %s'):format(inst_trunc), hl } },
      { { 'Processing ...', hl } },
    }
  elseif status == 'gen' then
    local preview = (req.result:gsub('.*\n%s*', ''))
    if #req.result == 0 then preview = '[thinking]' end
    hl = 'llama_hl_inst_virt_gen'
    virt_lines = {
      { { sep, hl } },
      { { ('Endpoint:    %s'):format(config.endpoint_inst), hl } },
      { { ('Model:       %s'):format(config.model_inst), hl } },
      { { ('Instruction: %s'):format(inst_trunc), hl } },
      { { ('Generating:  %4d tokens | %s'):format(req.n_gen, preview), hl } },
    }
  end

  if #virt_lines > 0 then
    virt_lines[#virt_lines + 1] = { { sep, hl } }
    req.extmark_virt = api.nvim_buf_set_extmark(req.bufnr, ns_inst, req.range[2] - 1, 0, {
      virt_lines = virt_lines,
    })
  end
end

function inst_remove(id)
  local req = inst_reqs[id]
  if req == nil then return end
  pcall(api.nvim_buf_del_extmark, req.bufnr, ns_inst, req.extmark)
  if req.extmark_virt ~= -1 then
    pcall(api.nvim_buf_del_extmark, req.bufnr, ns_inst, req.extmark_virt)
  end
  if req.job ~= nil then
    pcall(function() req.job:kill('sigterm') end)
  end
  inst_reqs[id] = nil
end

function inst_callback(bufnr, l0, l1, result)
  local lines = vim.split(result, '\n', { plain = true })
  while #lines > 0 and lines[#lines] == '' do
    table.remove(lines, #lines)
  end
  fn.deletebufline(bufnr, l0, l1)
  fn.append(l0 - 1, lines)
end

function M.inst_accept()
  local line = fn.line('.')
  for _, req in pairs(inst_reqs) do
    if req.status == 'ready' then
      inst_update_pos(req)
      if line >= req.range[1] and line <= req.range[2] then
        local bufnr, l0, l1, result = req.bufnr, req.range[1], req.range[2], req.result
        inst_remove(req.id)
        inst_callback(bufnr, l0, l1, result)
        return
      end
    end
  end
  api.nvim_feedkeys(vim.keycode('<Tab>'), 'n', false)
end

function M.inst_cancel()
  local line = fn.line('.')
  for _, req in pairs(inst_reqs) do
    if line >= req.range[1] and line <= req.range[2] then
      inst_remove(req.id)
      return
    end
  end
end

function M.inst_rerun()
  local lnum = fn.line('.')
  for _, req in pairs(inst_reqs) do
    inst_update_pos(req)
    if req.status == 'ready' and lnum >= req.range[1] and lnum <= req.range[2] then
      M.debug_log('inst_rerun')
      req.result = ''
      req.status = 'proc'
      req.n_gen = 0
      table.remove(req.inst_prev, #req.inst_prev)
      inst_update(req.id, 'proc')
      M.inst_send(req.id, req.inst_prev)
      return
    end
  end
end

function M.inst_continue()
  local lnum = fn.line('.')
  for _, req in pairs(inst_reqs) do
    inst_update_pos(req)
    if req.status == 'ready' and lnum >= req.range[1] and lnum <= req.range[2] then
      local inst = fn.input('Next instruction: ')
      if inst == '' then return end
      M.debug_log('inst_continue | ' .. inst)
      req.result = ''
      req.status = 'proc'
      req.inst = inst
      req.n_gen = 0
      inst_update(req.id, 'proc')
      req.inst_prev = M.inst_build(req.range[1], req.range[2], inst, req.inst_prev)
      M.inst_send(req.id, req.inst_prev)
      return
    end
  end
end

-- =====================================
-- Commands / init / setup
-- =====================================

local function setup_commands()
  api.nvim_create_user_command('LlamaEnable', M.enable, {})
  api.nvim_create_user_command('LlamaDisable', M.disable, {})
  api.nvim_create_user_command('LlamaToggle', M.toggle, {})
  api.nvim_create_user_command('LlamaToggleAutoFim', M.toggle_auto_fim, {})
  api.nvim_create_user_command('LlamaStatus', M.status, {})
  api.nvim_create_user_command('LlamaInstruct', function(opts)
    M.inst(opts.line1, opts.line2)
  end, { range = true })
  M.debug_setup()
end

function M.init()
  M.debug_log('llama.vim initializing ...')

  if fn.executable('curl') == 0 then
    vim.notify('llama.vim requires the "curl" command to be available', vim.log.levels.WARN)
    return
  end

  build_config()
  math.randomseed(os.time())
  setup_highlights()
  setup_commands()

  if config.enable_at_startup then
    M.enable()
  end
end

-- convenience wrapper: pass a table to override vim.g.llama_config, then init
function M.setup(opts)
  if opts ~= nil then
    vim.g.llama_config = vim.tbl_deep_extend('force', vim.g.llama_config or {}, opts)
  end
  M.init()
end

return M
