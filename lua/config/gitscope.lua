local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

local M = {}

M.has_modified = function()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, "modified") and vim.api.nvim_buf_is_loaded(buf) then
			return true
		end
	end
	return false
end

M.has_modified_in_repo = function()
	-- get the git root for cwd
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return false
	end

	-- files tracked by git that have unstaged changes
	local dirty = vim.fn.systemlist("git diff --name-only")
	local dirty_set = {}
	for _, f in ipairs(dirty) do
		dirty_set[git_root .. "/" .. f] = true
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, "modified") and vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if dirty_set[name] then
				return true
			end
		end
	end
	return false
end

M.pick = function(opts)
	opts = opts or {}
	local modified = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, "modified") and vim.api.nvim_buf_is_loaded(buf) then
			table.insert(modified, {
				bufnr = buf,
				name = vim.api.nvim_buf_get_name(buf),
			})
		end
	end
	if #modified == 0 then
		vim.notify("No unsaved buffers!", vim.log.levels.INFO)
		return
	end
	pickers
		.new(opts, {
			prompt_title = "Modified Buffers",
			finder = finders.new_table({
				results = modified,
				entry_maker = function(entry)
					local name = entry.name ~= "" and entry.name or "[No Name]"
					return {
						value = entry,
						display = "● " .. vim.fn.fnamemodify(name, ":~:."),
						ordinal = name,
						bufnr = entry.bufnr,
						filename = name,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = conf.grep_previewer(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local sel = action_state.get_selected_entry()
					vim.api.nvim_set_current_buf(sel.bufnr)
				end)
				map("i", "<C-s>", function()
					local sel = action_state.get_selected_entry()
					vim.api.nvim_buf_call(sel.bufnr, function()
						vim.cmd("write")
					end)
					vim.notify("Saved: " .. sel.value.name, vim.log.levels.INFO)
				end)
				map("i", "<C-a>", function()
					actions.close(prompt_bufnr)
					vim.cmd("wa")
					vim.notify("All buffers saved!", vim.log.levels.INFO)
				end)
				return true
			end,
		})
		:find()
end

return M
