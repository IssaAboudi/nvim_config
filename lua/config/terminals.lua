local Terminal = require("toggleterm.terminal").Terminal

local terms = {}
local labels = { "  main", "  secondary", "  extra", "  scratch" }

local function get(n)
	if not terms[n] then
		terms[n] = Terminal:new({ direction = "float", hidden = true })
	end
	return terms[n]
end

local last = 1
local last_is_claude = false
local M = {}

function M.toggle(n)
	last = n
	last_is_claude = false
	local term = get(n)
	term:toggle()
end

function M.cd_to_file()
	local git = vim.fs.find(".git", { upward = true })[1]
	local dir = git and vim.fs.dirname(git) or vim.fn.expand("%:p:h")
	get(last):send("cd " .. vim.fn.shellescape(dir), false)
	M.toggle(last)
end

function M.picker()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	local entries = {}
	table.insert(entries, { idx = 5, label = "  claude", term = _G.__term_claude })
	for i = 4, 1, -1 do
		table.insert(entries, { idx = i, label = labels[i], term = get(i) })
	end

	pickers
		.new({}, {
			prompt_title = "terminals",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(e)
					return {
						value = e,
						display = string.format("%d: %s", e.idx, e.label),
						ordinal = string.format("%d %s", e.idx, e.label),
					}
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "Terminal Preview",
				define_preview = function(self, entry)
					local term = entry.value.term
					if term and term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
						local lines = vim.api.nvim_buf_get_lines(term.bufnr, -50, -1, false)
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					else
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "(not started yet)" })
					end
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(buf, map)
				actions.select_default:replace(function()
					actions.close(buf)
					local sel = action_state.get_selected_entry().value
					if sel.idx == 5 then
						M.toggle_claude()
					else
						M.toggle(sel.idx)
					end
				end)
				return true
			end,
		})
		:find()
end

---- old picker ----
-- function M.picker()
-- 	local items = {}
-- 	for i = 1, 4 do
-- 		table.insert(items, string.format("%d: %s", i, labels[i]))
-- 	end
-- 	table.insert(items, "5:  claude")
-- 	vim.ui.select(items, { prompt = "Select terminal:" }, function(_, idx)
-- 		if not idx then
-- 			return
-- 		end
-- 		if idx == 5 then
-- 			M.toggle_claude()
-- 		else
-- 			M.toggle(idx)
-- 		end
-- 	end)
-- end

function M.toggle_claude()
	last_is_claude = true
	if not _G.__term_claude then
		_G.__term_claude = Terminal:new({ direction = "float", cmd = "claude", hidden = true, close_on_exit = false })
	end
	_G.__term_claude:toggle()
end

function M.toggle_last()
	if last_is_claude then
		M.toggle_claude()
	else
		M.toggle(last)
	end
end

return M
