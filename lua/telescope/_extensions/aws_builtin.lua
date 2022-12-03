local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope.utils")
local Terminal = require("toggleterm.terminal").Terminal

local M = {}

local sep = string.char(9)

local function close_telescope_prompt_ec2(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	actions.close(prompt_bufnr)
	local tmp_table = vim.split(selection.value, "\t")
	if vim.tbl_isempty(tmp_table) then
		return
	end
	return tmp_table[1]
end

local function gen_from_ec2(opts)
	local displayer = entry_display.create({
		separator = string.char(9),
		items = {
			{}, -- Instance
			{}, -- Name
		},
	})

	local function make_display(entry)
		return displayer({
			{ entry.value, "TelescopeResultsIdentifier" },
			entry.name,
		})
	end

	return function(line)
		local fields = vim.split(line, sep, true)
		return {
			display = make_display,
			instanceId = fields[1],
			name = fields[2],
		}
	end
end

local function connect_ec2(prompt_bufnr)
	local selection = close_telescope_prompt_ec2(prompt_bufnr)
	local cmd = table.concat(
		vim.tbl_flatten({
			"aws",
			"ssm",
			"start-session",
			"--target",
			selection,
		}),
		" "
	)
	vim.cmd(string.format('TermExec cmd="%s"', cmd))
	Terminal:new({
		cmd = cmd,
		start_in_insert = true,
		direction = "float",
		persist_size = false,
		persist_mode = false,
		float_opts = {
			width = 200,
			height = 90,
		},
	}):toggle()
end

M.ec2 = function(opts)
	opts = opts or {}
	local title = "ec2"
	local cmd = vim.tbl_flatten({
		"aws",
		"ec2",
		"describe-instances",
		"--query",
		"Reservations[].Instances[].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}",
		"--output",
		"text",
	})
	opts.entry_maker = utils.get_lazy_default(opts.entry_maker, gen_from_ec2, opts)
	pickers
		.new(opts, {
			prompt_title = title,
			finder = finders.new_oneshot_job(cmd),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(connect_ec2)
				return true
			end,
		})
		:find()
end

return M
