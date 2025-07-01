-- lua/nvim-cmdtool.lua

local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local last_command = nil -- Store the last command for repeating purposes.

-- Logfile (persistent) of commands + results.
local log_file = vim.fn.stdpath("data") .. "/vim-cmdtool.log"

local M = {}

local config = {
    -- Let's save cmdtool.json in config path. TODO: Make this configurable.
    commands_file = vim.fn.stdpath('config') .. '/cmdtool.json',
    prompt_title = 'CMD Tool',
}

local function log(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_entry = string.format("[%s] %s: %s\n", timestamp, level, message)

    local file = io.open(log_file, "a")
    if file then
        file:write(log_entry)
        file:close()
    end
end

-- Read the cmdtool.json and return the array of commands or empty.
local function load_commands()
    local file = io.open(config.commands_file, 'r')
    if not file then
        vim.notify('Commands file not found: ' .. config.commands_file, vim.log.levels.ERROR)
        return {}
    end

    local content = file:read('*all')
    file:close()

    local ok, commands = pcall(vim.json.decode, content)
    if not ok then
        vim.notify('Error parsing commands JSON file', vim.log.levels.ERROR)
        return {}
    end

    if type(commands) ~= 'table' then
        vim.notify('Commands file should contain an array of commands', vim.log.levels.ERROR)
        return {}
    end

    return commands
end

local function execute_command(entry)
    local command = entry.command or entry
    last_command = entry

    if command then
        log("INFO", "Starting COMMAND [" .. command .. "]")
        local cmd_type = 'vim' -- default
        if type(entry) == 'table' and entry.type then
            cmd_type = entry.type
        end

        if cmd_type == 'lua' then
            local ok, err = pcall(loadstring(command))
            if not ok then
                vim.notify('Error executing Lua command: ' .. err, vim.log.levels.ERROR)
                log("ERROR", 'Error executing Lua command: ' .. err)
            end
        elseif cmd_type == 'shell' then
            if vim.fn.exists(':FloatermNew') == 2 then
                vim.cmd('FloatermNew --autoclose=0 ' .. command)
            else
                vim.cmd('split | terminal ' .. command)
            end
        elseif cmd_type == 'shell_silent' then
            local output = vim.fn.system(command)
            if vim.v.shell_error == 0 then
                vim.notify('Command executed successfully:\n' .. output, vim.log.levels.INFO)
                log("INFO", 'Command finished successfully: ' .. output)
            else
                vim.notify('Command failed:\n' .. output, vim.log.levels.ERROR)
                log("ERROR", 'Command failed: ' .. output)
            end
        else
            -- Default to vim command
            local ok, err = pcall(vim.cmd, command)
            if not ok then
                vim.notify('Error executing vim command: ' .. err, vim.log.levels.ERROR)
                log("ERROR", 'Error executing vim command: ' .. err)
            end
        end
    end
end

local function execute_last()
    execute_command(last_command)
end

local function launch_command(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    if selection and selection.value then
        execute_command(selection.value)
    end
end



function M.cmdtool(opts)
    opts = opts or {}

    local commands = load_commands()
    if #commands == 0 then
        return
    end

    pickers.new(opts, {
        prompt_title = config.prompt_title,
        finder = finders.new_table {
            results = commands,
            entry_maker = function(entry)
                local display_text, command, description
                if type(entry) == 'string' then
                    -- Simple string command
                    display_text = entry
                    command = entry
                    description = ''
                elseif type(entry) == 'table' then
                    if entry.name and entry.command then
                        -- Full object with name and command
                        display_text = entry.name
                        command = entry.command
                        description = entry.description or ''
                    elseif entry.command then
                        -- Object with just command
                        display_text = entry.command
                        command = entry.command
                        description = entry.description or ''
                    else
                        -- Fallback
                        display_text = vim.inspect(entry)
                        command = vim.inspect(entry)
                        description = ''
                    end
                else
                    display_text = tostring(entry)
                    command = tostring(entry)
                    description = ''
                end

                return {
                    value = entry,
                    display = display_text .. (description ~= '' and ' - ' .. description or ''),
                    ordinal = display_text .. ' ' .. description,
                }
            end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(launch_command)
            return true
        end,
    }):find()
end

function M.setup(opts)
    opts = opts or {}
    config = vim.tbl_extend('force', config, opts)

    for i, t in ipairs(load_commands()) do
        if t.on_save == 1 then
            vim.api.nvim_create_autocmd("BufWritePost", {
                callback = function()
                    execute_command(t)
                end,
            })
        end
    end
    -- Create user command
    vim.api.nvim_create_user_command('CMDtool', function()
        M.cmdtool()
    end, {
        desc = 'Open cmdtool in Telescope'
    })

    vim.api.nvim_create_user_command('CMDtoolRepeat', function()
        execute_last()
    end, {
        desc = 'Repeat last executed command'
    })

    vim.api.nvim_create_user_command("CMDtoolLog", function()
        vim.cmd("split " .. log_file)
    end, {})

end

return M
