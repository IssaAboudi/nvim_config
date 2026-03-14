local harpoon = require("harpoon")
local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Open Harpoon marks in a Telescope picker
local function harpoon_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end
	pickers
		.new({}, {
			prompt_title = "Harpoon",
			finder = finders.new_table({ results = file_paths }),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				-- Open file on <CR>
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					harpoon:list():select(selection.index)
				end)
				-- Remove from Harpoon list with <C-d>
				map("i", "<C-d>", function()
					local selection = action_state.get_selected_entry()
					harpoon:list():remove_at(selection.index)
					-- Refresh the picker
					actions.close(prompt_bufnr)
					harpoon_telescope(harpoon:list())
				end)
				return true
			end,
		})
		:find()
end

return {
	harpoon_telescope = harpoon_telescope,
}
