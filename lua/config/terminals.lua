local Terminal = require("toggleterm.terminal").Terminal

local terms = {}
local labels = { "  main", "  secondary", "  extra", "  scratch", "  opencode" }

local function get(n)
	if not terms[n] then
		terms[n] = Terminal:new({ direction = "float", hidden = true })
	end
	return terms[n]
end

local last = 1
local last_is_claude = false
local M = {}
local opencode_launched = false

function M.toggle_opencode()
	last = 5
	last_is_claude = false
	local term = get(5)
	term:toggle()
	if not opencode_launched then
		opencode_launched = true
		vim.schedule(function()
			term:send("opencode", false)
		end)
	end
end

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
					M.toggle(sel.idx)
				end)
				return true
			end,
		})
		:find()
end

function M.toggle_last()
	M.toggle(last)
end

return M
