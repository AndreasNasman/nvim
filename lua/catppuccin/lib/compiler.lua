local M = {}

-- Credit: https://github.com/EdenEast/nightfox.nvim
local fmt = string.format
local function inspect(t)
	local list = {}
	for k, v in pairs(t) do
		local q = type(v) == "string" and [["]] or ""
		table.insert(list, fmt([[%s = %s%s%s]], k, q, v, q))
	end

	table.sort(list)
	return fmt([[{ %s }]], table.concat(list, ", "))
end

function M.compile()
	local theme = require("catppuccin.lib.mapper").apply()
	local lines = {
		[[
-- This file is autogenerated by CATPPUCCIN.
-- Do not make changes directly to this file.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
	vim.cmd("syntax reset")
end
vim.g.colors_name = "catppuccin"]],
	}
	local config = require("catppuccin.config").options
	local custom_highlights = config.custom_highlights
	for property, value in pairs(theme.properties) do
		if type(value) == "string" then
			table.insert(lines, fmt('vim.o.%s = "%s"', property, value))
		elseif type(value) == "bool" then
			table.insert(lines, fmt("vim.o.%s = %s", property, value))
		elseif type(value) == "table" then
			table.insert(lines, fmt("vim.o.%s = %s", property, inspect(value)))
		end
	end
	local tbl = vim.tbl_deep_extend("keep", theme.integrations, theme.base)
	tbl = vim.tbl_deep_extend("keep", custom_highlights, tbl)

	for group, color in pairs(tbl) do
		if color.link then
			table.insert(lines, fmt([[vim.api.nvim_set_hl(0, "%s", { link = "%s" })]], group, color.link))
		else
			if color.style then
				if color.style ~= "NONE" then
					if type(color.style) == "table" then
						for _, style in ipairs(color.style) do
							color[style] = true
						end
					else
						color[color.style] = true
					end
				end
			end

			color.style = nil
			vim.api.nvim_set_hl(0, group, color)
			table.insert(lines, fmt([[vim.api.nvim_set_hl(0, "%s", %s)]], group, inspect(color)))
		end
	end

	if config.term_colors then
		local colors = {
			"overlay0",
			"red",
			"green",
			"yellow",
			"blue",
			"pink",
			"sky",
			"text",
			"overlay1",
			"red",
			"green",
			"yellow",
			"blue",
			"pink",
			"sky",
			"text",
		}
		for i = 0, 15 do
			table.insert(lines, fmt('vim.g.terminal_color_%d = "%s"', i, theme.terminal[colors[i + 1]]))
		end
	end
	os.execute(
		string.format("mkdir %s %s", vim.loop.os_uname().sysname == "Windows" and "" or "-p", config.compile.path)
	)
	local file = io.open(
		config.compile.path
			.. (vim.loop.os_uname().sysname == "Windows" and "\\" or "/")
			.. vim.g.catppuccin_flavour
			.. config.compile.suffix
			.. ".lua",
		"w"
	)
	file:write(table.concat(lines, "\n"))
	file:close()
end

function M.clean()
	local config = require("catppuccin.config").options
	local compiled_path = config.compile.path
		.. (vim.loop.os_uname().sysname == "Windows" and "\\" or "/")
		.. vim.g.catppuccin_flavour
		.. config.compile.suffix
		.. ".lua"
	os.remove(compiled_path)
end

return M
