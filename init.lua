-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true
vim.opt.number = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = "a"
-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.o.breakindent = true
-- Save undo history
vim.o.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true
-- Keep signcolumn on by default
vim.o.signcolumn = "yes"
-- Decrease update time
vim.o.updatetime = 250
-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 5

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- KEYBINDINGS

-- clear highlighting
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<CR>", { desc = "clear highlighting" })

vim.keymap.set("n", "<leader>gds", function()
	vim.cmd("Gdiffsplit")
end, { desc = "Git diff split current" })

-- go back to netrw
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, {
	desc = "Open netrw",
})

-- fullscreen terminal
vim.keymap.set("t", "<C-f>", function()
	local win = vim.api.nvim_get_current_win()
	local cfg = vim.api.nvim_win_get_config(win)
	if not vim.w[win].saved_cfg then
		vim.w[win].saved_cfg = { width = cfg.width, height = cfg.height, row = cfg.row, col = cfg.col }
		vim.api.nvim_win_set_config(win, {
			relative = "editor",
			width = vim.o.columns - 2,
			height = vim.o.lines - 4,
			row = 1,
			col = 1,
		})
	else
		local s = vim.w[win].saved_cfg
		vim.api.nvim_win_set_config(win, {
			relative = "editor",
			width = s.width,
			height = s.height,
			row = s.row,
			col = s.col,
		})
		vim.w[win].saved_cfg = nil
	end
end, { desc = "Toggle terminal fullscreen" })

vim.keymap.set("n", "<c-f>", "<Nop>")

-- git fetch
vim.keymap.set("n", "<leader>gf", function()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		return
	end
	local start_dir = vim.fn.fnamemodify(bufname, ":p:h")
	local git = vim.fs.find({ ".git" }, { upward = true, path = start_dir })[1]
	if not git then
		return
	end
	local cwd = vim.fs.dirname(git)

	local function git(cmd)
		return vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " " .. cmd):gsub("%s+", "")
	end

	local function get_behind(local_ref, remote_ref)
		local count = git(string.format("rev-list %s..%s --count 2>/dev/null", local_ref, remote_ref))
		return tonumber(count)
	end

	vim.fn.jobstart("git -C " .. vim.fn.shellescape(cwd) .. " fetch origin 2>&1", {
		stdout_buffered = true,
		stderr_buffered = true,
		on_exit = function()
			local branch = git("rev-parse --abbrev-ref HEAD")
			local msgs = {}

			-- Current branch vs origin/<branch>
			local cur_behind = get_behind("HEAD", "origin/" .. branch)
			if cur_behind and cur_behind > 0 then
				table.insert(
					msgs,
					string.format("⚠️  %s is %d commit(s) behind origin/%s", branch, cur_behind, branch)
				)
			elseif cur_behind then
				table.insert(msgs, string.format("✅ %s is up to date with origin/%s", branch, branch))
			else
				table.insert(msgs, string.format("ℹ️  No upstream found for %s", branch))
			end

			-- Local staging vs origin/staging
			if branch ~= "staging" then
				local staging_exists = git("rev-parse --verify origin/staging 2>/dev/null")
				if staging_exists ~= "" then
					local local_staging_exists = git("rev-parse --verify staging 2>/dev/null")
					if local_staging_exists ~= "" then
						local stg_behind = get_behind("staging", "origin/staging")
						if stg_behind and stg_behind > 0 then
							table.insert(
								msgs,
								string.format("⚠️  staging is %d commit(s) behind origin/staging", stg_behind)
							)
						else
							table.insert(msgs, "✅ staging is up to date with origin/staging")
						end
					else
						table.insert(msgs, "ℹ️  No local staging branch found")
					end
				else
					table.insert(msgs, "ℹ️  origin/staging not found")
				end
			end

			vim.notify(table.concat(msgs, "\n"), vim.log.levels.WARN)
		end,
	})
end, { desc = "Git fetch origin and check current branch + staging" })

-- diff current buffers
vim.keymap.set("n", "<leader>gdd", function()
	vim.cmd("windo diffthis")
end, { desc = "diff current buffers" })
-- turn off diff
vim.keymap.set("n", "<leader>gdo", function()
	vim.cmd("windo diffoff")
end, { desc = "diff current buffers" })

-- git pull
vim.keymap.set("n", "<leader>gp", ":Git pull<CR>", { desc = "git pull" })

-- git push
vim.keymap.set("n", "<leader>gP", function()
	local modified_buffers = require("config.gitscope")
	if modified_buffers.has_modified() then
		modified_buffers.pick()
		vim.notify("Unsaved buffers — save before pushing!", vim.log.levels.WARN)
	else
		vim.cmd("Git push -u origin HEAD")
	end
end, { desc = "git push & set upstream" })

-- git good?
vim.keymap.set("n", "<leader>gg", function()
	local has_modified = false
	local modified_buffers = require("config.gitscope")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, "modified") then
			has_modified = true
			break
		end
	end
	if has_modified then
		modified_buffers.pick() -- surface them first
	end
end, { desc = "[G]it [G]ood to push ?" })
vim.keymap.set("n", "<leader>gcb", ":Git checkout -b ", { desc = "Git checkout new branch" })

-- copy current open fp
vim.keymap.set("n", "<leader>pp", function()
	local path = vim.fn.expand("%:p:h")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path)
end, { desc = "Copy current file path" })

-- copy current open fp with filename
vim.keymap.set("n", "<leader>pa", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path)
end, { desc = "Copy path to current file" })

-- paste around delimiter
vim.keymap.set("n", "<leader>P", function()
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	local char = line:sub(col, col)

	local allowed = {
		["'"] = true,
		['"'] = true,
		["`"] = true,
		["("] = true,
		["{"] = true,
		["["] = true,
		["<"] = true,
	}

	if not allowed[char] then
		vim.notify("Put cursor on an opening delimiter: ' \" ` ( { [", vim.log.levels.WARN)
		return
	end

	local keys = '"_ci' .. char .. "<C-r>+<Esc>"
	keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Paste inside delimiter under cursor" })

vim.keymap.set("n", "<leader>j", "10j", { desc = "Scroll down faster" })
vim.keymap.set("n", "<leader>k", "10k", { desc = "Scroll up faster" })

vim.keymap.set("n", "<leader>ID", function()
	local date = os.date("%d/%m/%Y")
	local text = string.format("[[%s]]:", date)
	vim.api.nvim_put({ text }, "c", true, true)
end)

-- Diagnostic Config & Keymaps
-- See :help vim.diagnostic.Opts
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },

	-- Can switch between these as you prefer
	virtual_text = true, -- Text shows up at the end of the line
	virtual_lines = false, -- Teest shows up underneath the line, with virtual lines

	-- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
	jump = { float = true },
})

vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- Filetype detection for Java
vim.filetype.add({
	extension = {
		java = "java",
	},
})

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require("lazy").setup({
	-- NOTE: Plugins can be added via a link or github org/name. To run setup automatically, use `opts = {}`
	{ "NMAC427/guess-indent.nvim", opts = {} },

	-- Alternatively, use `config = function() ... end` for full control over the configuration.
	-- If you prefer to call `setup` explicitly, use:
	--    {
	--        'lewis6991/gitsigns.nvim',
	--        config = function()
	--            require('gitsigns').setup({
	--                -- Your gitsigns configuration here
	--            })
	--        end,
	--    }
	--
	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`.
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
	--
	-- This is often very useful to both group configuration, as well as handle
	-- lazy loading plugins that don't need to be loaded immediately at startup.
	--
	-- For example, in the following configuration, we use:
	--  event = 'VimEnter'
	--
	-- which loads which-key before all the UI elements are loaded. Events can be
	-- normal autocommands events (`:help autocmd-events`).
	--
	-- Then, because we use the `opts` key (recommended), the configuration runs
	-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			-- delay between pressing a key and opening which-key (milliseconds)
			delay = 0,
			icons = { mappings = vim.g.have_nerd_font },

			-- Document existing key chains
			spec = {
				{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]erminal" },
				{ "<leader>g", group = "[G]it Actions" },
			},
		},
		enabled = true,
	},

	-- NOTE: Plugins can specify dependencies.
	--
	-- The dependencies are proper plugin specifications as well - anything
	-- you do for a plugin at the top level, you can do for a dependency.
	--
	-- Use the `dependencies` key to specify the dependencies of a particular plugin
	{
		"tpope/vim-fugitive",
	},

	{
		"arismoko/buddy.nvim",
		dependencies = {
			"nvim-mini/mini.nvim",
			"nvim-neotest/nvim-nio",
		},
		lazy = false,
		config = function()
			require("buddy").setup({
				auto_start = true,
				port = 7234,
				auth = false,
			})
		end,
	},

	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			-- opencode terminal
			{
				"<c-`>",
				function()
					require("config.terminals").toggle_opencode()
				end,
				desc = "OpenCode terminal",
				mode = { "n", "t" },
			},
			-- individual terminals
			{
				"<c-1>",
				function()
					require("config.terminals").toggle(1)
				end,
				desc = "Terminal 1",
				mode = { "n", "t" },
			},
			{
				"<c-2>",
				function()
					require("config.terminals").toggle(2)
				end,
				desc = "Terminal 2",
				mode = { "n", "t" },
			},
			{
				"<c-3>",
				function()
					require("config.terminals").toggle(3)
				end,
				desc = "Terminal 3",
				mode = { "n", "t" },
			},
			{
				"<c-4>",
				function()
					require("config.terminals").toggle(4)
				end,
				desc = "Terminal 4",
				mode = { "n", "t" },
			},

			-- picker
			{
				"<leader>tt",
				function()
					require("config.terminals").picker()
				end,
				desc = "Pick terminal",
			},
			-- toggle last used terminal
			{
				"<c-\\>",
				function()
					require("config.terminals").toggle_last()
				end,
				desc = "Toggle last terminal",
				mode = { "n", "t", "i" },
			},
		},
		opts = {
			open_mapping = nil,
			direction = "float",
			shade_terminals = false,
		},
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },

		keys = {
			{
				"<leader>a",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon add",
			},
			{
				"<leader>H",
				function()
					local harpoon = require("harpoon")
					require("config.telepoon").harpoon_telescope(harpoon:list())
				end,
				desc = "Harpoon menu",
			},
			{
				"<leader>h",
				function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon menu",
			},
			{
				"<leader>1",
				function()
					require("harpoon"):list():select(1)
				end,
				desc = "Harpoon 1",
			},
			{
				"<leader>2",
				function()
					require("harpoon"):list():select(2)
				end,
				desc = "Harpoon 2",
			},
			{
				"<leader>3",
				function()
					require("harpoon"):list():select(3)
				end,
				desc = "Harpoon 3",
			},
			{
				"<leader>4",
				function()
					require("harpoon"):list():select(4)
				end,
				desc = "Harpoon 4",
			},
		},
		config = function()
			require("harpoon"):setup({
				default = {
					display = function(list_item)
						if not list_item or not list_item.value then
							return ""
						end
						local parts = vim.split(list_item.value, "/")
						local n = #parts
						if n == 1 then
							return parts[1]
						end
						return string.format("%s/%s", parts[n - 1], parts[n])
					end,
				},
			})
		end,
	},
	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		-- By default, Telescope is included and acts as your picker for everything.

		-- If you would like to switch to a different picker (like snacks, or fzf-lua)
		-- you can disable the Telescope plugin by setting enabled to false and enable
		-- your replacement picker by requiring it explicitly (e.g. 'custom.plugins.snacks')

		-- Note: If you customize your config for yourself,
		-- it’s best to remove the Telescope plugin config entirely
		-- instead of just disabling it here, to keep your config clean.

		enabled = true,
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			-- Telescope is a fuzzy finder that comes with a lot of different things that
			-- it can fuzzy find! It's more than just a "file finder", it can search
			-- many different aspects of Neovim, your workspace, LSP, and more!
			--
			-- The easiest way to use Telescope, is to start by doing something like:
			--  :Telescope help_tags
			--
			-- After running this command, a window will open up and you're able to
			-- type in the prompt window. You'll see a list of `help_tags` options and
			-- a corresponding preview of the help.
			--
			-- Two important keymaps to use while in Telescope are:
			--  - Insert mode: <c-/>
			--  - Normal mode: ?
			--
			-- This opens a window that shows you all of the keymaps for the current
			-- Telescope picker. This is really useful to discover what Telescope can
			-- do as well as how to actually do it!

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				--
				-- defaults = {
				--   mappings = {
				--     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
				--   },
				-- },
				-- pickers = {}
				defaults = {
					path_display = { "filename_first" },
					--better layout behavior
					layout_config = {
						horizontal = {
							preview_width = 0.6,
						},
					},
					initial_mode = "normal",
					-- Toggle preview with Ctrl-p
					mappings = {
						i = {
							["<C-p>"] = require("telescope.actions.layout").toggle_preview,
						},
						n = {
							["<C-p>"] = require("telescope.actions.layout").toggle_preview,
							["q"] = require("telescope.actions").close,
						},
					},
				},
				extensions = {
					["ui-select"] = require("telescope.themes").get_dropdown(),
				},
			})

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			local builtin = require("telescope.builtin")
			--vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			--vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })

			--vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch thi[S] word" })
			vim.keymap.set("n", "<leader>ss", builtin.live_grep, { desc = "[S]earch for [W]ord by grep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			--vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
			--vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			local function git_root()
				local out = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
				if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
					return nil
				end
				return out[1]
			end

			local function buffer_git_root()
				local bufname = vim.api.nvim_buf_get_name(0)
				if bufname == "" then
					return nil
				end

				local start_dir = vim.fn.fnamemodify(bufname, ":p:h")

				local git = vim.fs.find({ ".git" }, {
					upward = true,
					path = start_dir,
				})[1]

				if git then
					return vim.fs.dirname(git)
				end

				return nil
			end

			-- SEARCHING KEYBINDS
			-- search branches
			vim.keymap.set("n", "<leader>gb", function()
				local root = buffer_git_root()
				if not root then
					vim.notify("Vim was not opened a git repository", vim.log.levels.WARN)
					return
				end
				require("telescope.builtin").git_branches({
					cwd = root,
					show_remote_tracking_branches = false,
				})
			end, { desc = "Git local branches" })
			-- search working commits
			vim.keymap.set("n", "<leader>gs", function()
				local root = buffer_git_root()
				if not root then
					vim.notify("Not in a git repository", vim.log.levels.WARN)
					return
				end
				require("telescope.builtin").git_status({
					cwd = root,
				})
			end, { desc = "Git status files" })
			-- search all files in honey dir
			vim.keymap.set("n", "<leader>sfa", function()
				builtin.find_files({ cwd = vim.fn.expand("~/Dev/honey/") })
			end, { desc = "[S]earch [F]iles" })
			-- search current repo dir
			vim.keymap.set("n", "<leader>sff", function()
				local root = buffer_git_root()
				if not root then
					vim.notify("Not in a git repository", vim.log.levels.WARN)
					return
				end
				builtin.find_files({ cwd = root })
			end, { desc = "Find files (git root)" })

			-- This runs on LSP attach per buffer (see main LSP attach function in 'neovim/nvim-lspconfig' config for more info,
			-- it is better explained there). This allows easily switching between pickers if you prefer using something else!
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
				callback = function(event)
					local buf = event.buf

					-- Find references for the word under your cursor.
					vim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })

					-- Jump to the implementation of the word under your cursor.
					-- Useful when your language has ways of declaring types without an actual implementation.
					vim.keymap.set(
						"n",
						"gri",
						builtin.lsp_implementations,
						{ buffer = buf, desc = "[G]oto [I]mplementation" }
					)

					-- Jump to the definition of the word under your cursor.
					-- This is where a variable was first declared, or where a function is defined, etc.
					-- To jump back, press <C-t>.
					vim.keymap.set("n", "grd", builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })

					-- Fuzzy find all the symbols in your current document.
					-- Symbols are things like variables, functions, types, etc.
					vim.keymap.set(
						"n",
						"gO",
						builtin.lsp_document_symbols,
						{ buffer = buf, desc = "Open Document Symbols" }
					)

					-- Fuzzy find all the symbols in your current workspace.
					-- Similar to document symbols, except searches over your entire project.
					vim.keymap.set(
						"n",
						"gW",
						builtin.lsp_dynamic_workspace_symbols,
						{ buffer = buf, desc = "Open Workspace Symbols" }
					)

					-- Jump to the type of the word under your cursor.
					-- Useful when you're not sure what type a variable is and you want to see
					-- the definition of its *type*, not where it was *defined*.
					vim.keymap.set(
						"n",
						"grt",
						builtin.lsp_type_definitions,
						{ buffer = buf, desc = "[G]oto [T]ype Definition" }
					)
				end,
			})

			-- Override default behavior and theme when searching
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim config" })

			vim.keymap.set("n", "<leader>sh", function()
				builtin.find_files({ cwd = vim.fn.expand("~/.config/hypr") })
			end, { desc = "[S]earch [H]yprland config" })

			vim.keymap.set("n", "<leader>sc", function()
				builtin.find_files({ cwd = vim.fn.expand("~/.config/") })
			end, { desc = "[S]earch all [C]onfig files" })
		end,
	},

	{ -- Main LSP Configuration (updated for vim.lsp.config / ts_ls)
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", opts = {} },
			{ "williamboman/mason-lspconfig.nvim", opts = {} },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			-- Capabilities (blink.cmp)
			local ok_blink, blink = pcall(require, "blink.cmp")
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			if ok_blink and blink.get_lsp_capabilities then
				capabilities = blink.get_lsp_capabilities()
			end

			local function disable_formatting(client)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end

			-- Buffer-local keymaps when LSP attaches
			local on_attach = function(_, bufnr)
				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end

				map("n", "gd", vim.lsp.buf.definition, "Go to definition")
				map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
				map("n", "gr", vim.lsp.buf.references, "References")
				map("n", "gi", vim.lsp.buf.implementation, "Implementation")
				map("n", "K", vim.lsp.buf.hover, "Hover")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
			end

			-- Mason
			require("mason").setup()
			require("mason-lspconfig").setup({
				-- These are lspconfig server names (NOT Mason package names)
				ensure_installed = { "lua_ls", "ts_ls", "jsonls", "gopls" },
			})

			-- Mason tool installer (these are Mason package names)
			require("mason-tool-installer").setup({
				ensure_installed = {
					"lua-language-server",
					"stylua",
					"typescript-language-server",
					"eslint-lsp",
					"prettierd",
					"json-lsp",
					"google-java-format",
					"gopls",
					"goimports",
					"gofumpt",
				},
			})

			-- Helper to register + enable servers using Neovim 0.11 API
			local function setup_server(name, opts)
				opts = opts or {}
				opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
				opts.on_attach = opts.on_attach or on_attach
				vim.lsp.config(name, opts)
				vim.lsp.enable(name)
			end

			-- lua_ls
			setup_server("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						runtime = { version = "LuaJIT" },
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			})

			-- TypeScript/JavaScript (new name; tsserver is deprecated)
			setup_server("ts_ls", {
				on_attach = function(client, bufnr)
					disable_formatting(client)
				end,
			})

			setup_server("eslint", {
				on_attach = function(client, bufnr)
					disable_formatting(client)
				end,
			})

			-- JSON
			setup_server("jsonls", {
				on_attach = function(client, bufnr)
					disable_formatting(client)
				end,
			})

			-- Java (jdtls)
			setup_server("jdtls", {
				settings = {
					java = {
						eclipse = {
							downloadSources = true,
						},
						configuration = {
							updateBuildConfiguration = "interactive",
						},
						maven = {
							downloadSources = true,
						},
						implementationsCodeLens = {
							enabled = true,
						},
						referencesCodeLens = {
							enabled = true,
						},
						inlayHints = {
							parameterNames = {
								enabled = "all",
							},
						},
					},
				},
			})

			-- fidget (guarded)
			local ok_fidget, fidget = pcall(require, "fidget")
			if ok_fidget then
				fidget.setup({})
			end
		end,
	},

	-- Go (gopls)
	setup_server("gopls", {
		settings = {
			gopls = {
				gofumpt = true,
				staticcheck = true,
				analyses = {
					unusedparams = true,
					shadow = true,
				},
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
	})({ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				java = { "google-java-format" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				go = { "prettierd", "prettier", stop_after_first = true },

				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
			},
		},
	}),

	{ -- Autocompletion
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			-- Snippet Engine
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					-- {
					--   'rafamadriz/friendly-snippets',
					--   config = function()
					--     require('luasnip.loaders.from_vscode').lazy_load()
					--   end,
					-- },
				},
				opts = {},
			},
		},
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = {
				-- 'default' (recommended) for mappings similar to built-in completions
				--   <c-y> to accept ([y]es) the completion.
				--    This will auto-import if your LSP supports it.
				--    This will expand snippets if the LSP sent a snippet.
				-- 'super-tab' for tab to accept
				-- 'enter' for enter to accept
				-- 'none' for no mappings
				--
				-- For an understanding of why the 'default' preset is recommended,
				-- you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				--
				-- All presets have the following mappings:
				-- <tab>/<s-tab>: move to right/left of your snippet expansion
				-- <c-space>: Open menu or open docs if already open
				-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
				-- <c-e>: Hide menu
				-- <c-k>: Toggle signature help
				--
				-- See :h blink-cmp-config-keymap for defining your own keymap
				preset = "default",

				-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
				--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				-- By default, you may press `<c-space>` to show the documentation.
				-- Optionally, set `auto_show = true` to show the documentation after a delay.
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},

			sources = {
				default = { "lsp", "path", "snippets" },
			},

			snippets = { preset = "luasnip" },

			-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
			-- which automatically downloads a prebuilt binary when enabled.
			--
			-- By default, we use the Lua implementation instead, but you may enable
			-- the rust implementation via `'prefer_rust_with_warning'`
			--
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = { implementation = "lua" },

			-- Shows a signature help window while you type arguments for a function
			signature = { enabled = true },
		},
	},

	{ -- You can easily change to a different colorscheme.
		-- Change the name of the colorscheme plugin below, and then
		-- change the command in the config to whatever the name of that colorscheme is.
		--
		-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
		"folke/tokyonight.nvim",
		priority = 1000, -- Make sure to load this before all the other start plugins.
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("tokyonight").setup({
				styles = {
					comments = { italic = false }, -- Disable italics in comments
				},
			})

			-- Load the colorscheme here.
			-- Like many other themes, this one has different styles, and you could load
			-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},

	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({
				sections = {
					lualine_a = {},
					lualine_b = { "branch" },
					lualine_c = { { "filename", path = 0, symbols = { modified = "  ●  UNSAVED" } } },
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
			})
		end,
	},

	{ -- Treesitter
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				vim.notify("nvim-treesitter not available. Run :Lazy sync", vim.log.levels.ERROR)
				return
			end

			configs.setup({
				ensure_installed = {
					"bash",
					"c",
					"diff",
					"html",
					"lua",
					"go",
					"markdown",
					"markdown_inline",
					"query",
					"vim",
					"vimdoc",
					"java",

					-- JS / TS (recommended)
					"javascript",
					"typescript",
					"tsx",
					"json",
				},
				highlight = { enable = true },
			})
		end,
	},

	-- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
	-- init.lua. If you want these files, they are in the repository, so you can just download them and
	-- place them in the correct locations.

	-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
	--
	--  Here are some example plugins that I've included in the Kickstart repository.
	--  Uncomment any of the lines below to enable them (you will need to restart nvim).
	--
	-- require 'kickstart.plugins.debug',
	-- require 'kickstart.plugins.indent_line',
	-- require 'kickstart.plugins.lint',
	-- require 'kickstart.plugins.autopairs',
	-- require 'kickstart.plugins.neo-tree',
	-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

	-- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
	--    This is the easiest way to modularize your config.
	--
	--  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
	-- { import = 'custom.plugins' },
	--
	-- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
	-- Or use telescope!
	-- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
	-- you can continue same window with `<space>sr` which resumes last telescope search
}, {
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
