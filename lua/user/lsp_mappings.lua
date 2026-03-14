-- ~/.config/nvim/lua/user/lsp_mappings.lua
local ok_telescope, builtin = pcall(require, "telescope.builtin")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach_mappings", { clear = true }),
	callback = function(event)
		local buf = event.buf
		-- debug print so you can confirm the autocmd fired
		vim.schedule(function()
			vim.notify("LspAttach fired for buf " .. tostring(buf), vim.log.levels.INFO)
		end)

		-- helper to set buffer-local mapping safely
		local function bufmap(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
		end

		-- If telescope is present, prefer its pickers (they're great for multiple results).
		if ok_telescope then
			bufmap("n", "gd", function()
				local ok = pcall(builtin.lsp_definitions)
				if not ok then
					vim.lsp.buf.definition()
				end
			end, "Go to definition (telescope then fallback)")

			bufmap("n", "gr", function()
				local ok = pcall(builtin.lsp_references)
				if not ok then
					vim.lsp.buf.references()
				end
			end, "References (telescope)")

			bufmap("n", "gri", function()
				local ok = pcall(builtin.lsp_implementations)
				if not ok then
					vim.lsp.buf.implementation()
				end
			end, "Implementations (telescope)")

			bufmap("n", "grd", function()
				local ok = pcall(builtin.lsp_definitions)
				if not ok then
					vim.lsp.buf.definition()
				end
			end, "Definitions (telescope)")
		else
			-- fallback to direct LSP calls if telescope isn't available
			bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
			bufmap("n", "gr", vim.lsp.buf.references, "References")
			bufmap("n", "gri", vim.lsp.buf.implementation, "Implementation")
			bufmap("n", "grd", vim.lsp.buf.definition, "Definition")
		end

		-- hover
		bufmap("n", "K", vim.lsp.buf.hover, "Hover docs")
	end,
})
