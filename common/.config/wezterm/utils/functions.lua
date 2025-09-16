local M = {}
-- General utilities
--- Merge all the given tables into a single one and return it.
---@param ... table
---@return table
function M.merge_all(...)
	local ret = {}
	for _, tbl in ipairs({ ... }) do
		for k, v in pairs(tbl) do
			ret[k] = v
		end
	end
	return ret
end

--- Deep clone the given table.
---@param original table
---@return table
function M.deepclone(original)
	local clone = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			clone[k] = M.deepclone(v)
		else
			clone[k] = v
		end
	end
	return clone
end

---@param t table|any
---@return boolean
local is_list = function(t)
	if type(t) ~= "table" then
		return false
	end
	-- a list has list indices, an object does not
	return ipairs(t)(t, 0) and true or false
end

--- Flatten the given list of (item or (list of (item or ...)) to a list of item.
--- (nested lists are supported)
---@param list table
---@return table
function M.flatten_list(list)
	local flattened_list = {}
	for _, item in ipairs(list) do
		if is_list(item) then
			for _, sub_item in ipairs(M.flatten_list(item)) do
				table.insert(flattened_list, sub_item)
			end
		else
			table.insert(flattened_list, item)
		end
	end
	return flattened_list
end

-- File utilities
function M.file_exists(name)
	local file = io.open(name, "r")
	if file then
		io.close(file)
		return true
	end
	return false
end

function M.basename(path)
	return string.gsub(path, "(.*[/\\])(.*)", "%2")
end

-- Tab utilities
function M.get_tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end
	return tab_info.active_pane.title:gsub("^Copy mode: ", "")
end

function M.get_cwd(pane, max_width)
	local cwd = pane:get_current_working_dir()
	if not cwd then
		return ""
	end

	if type(cwd) == "userdata" then
		cwd = cwd.path
	end

	local home = os.getenv("HOME")
	if home then
		cwd = cwd:gsub("^" .. home, "~")
	end

	if max_width and #cwd > max_width then
		cwd = ".." .. cwd:sub(-(max_width - 2))
	end

	return cwd
end

-- Visual effects
function M.flash_screen(window)
	return
end

return M
