local M = {}

-- Model name to flag mapping
local model_flags = {
    ["opus"] = "--opus",
    ["sonnet"] = "--sonnet",
    ["gpt-4"] = "--4",
    ["gpt-4o"] = "--4o",
    ["gpt-4o-mini"] = "--mini",
    ["gpt-4-turbo"] = "--4-turbo",
    ["gpt-3.5-turbo"] = "--35turbo",
    ["deepseek"] = "--deepseek",
    ["o1-mini"] = "--o1-mini",
    ["o1-preview"] = "--o1-preview"
}

-- Default configuration
local default_config = {
    dark_mode = true,
    command = 'aider',
    -- Main options
    model = 'sonnet', -- Default model
    mode = 'diff',    -- 'diff' or 'inline'
    -- Float window options
    float_opts = {
        relative = 'editor',
        width = 0.8,  -- As fraction of editor width
        height = 0.8, -- As fraction of editor height
        style = 'minimal',
        border = 'rounded',
        title = ' Aider ',
        title_pos = 'center',
    },
}

local function config_to_args(config)
    local args = {}

    table.insert(args, '--chat-mode=code')
    table.insert(args, '--no-auto-commits')
    table.insert(args, '--subtree-only')
    table.insert(args, '--cache-prompts')
    table.insert(args, '--no-stream')
    if config.dark_mode then
        table.insert(args, '--dark-mode')
    end
    if config.model then
        local flag = model_flags[config.model]
        if flag then
            table.insert(args, flag)
        else
            table.insert(args, '--model')
            table.insert(args, config.model)
        end
    end

    return args
end

local function build_aider_command(config, file_path, message)
    local args = config_to_args(config)
    local cmd = config.command

    table.insert(args, '--file')
    table.insert(args, file_path)

    if message then
        table.insert(args, '--message')
        -- Escape special characters and wrap in single quotes
        local escaped_message = message:gsub("'", "'\\''") -- Escape single quotes
        table.insert(args, "'" .. escaped_message .. "'")
    end

    for _, arg in ipairs(args) do
        cmd = cmd .. ' ' .. arg
    end

    return cmd
end

-- Check if aider is installed
local function check_aider_installed()
    local handle = io.popen("which aider")
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
end

-- 獲取文字內容
local function get_visual_selection(is_visual)
    if not is_visual then
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    end

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 1 then
        lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
        lines[1] = string.sub(lines[1], start_pos[3])
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    return table.concat(lines, "\n")
end

local function diff_buf(left, right)
    if not vim.api.nvim_buf_is_valid(left) or not vim.api.nvim_buf_is_valid(right) then
        vim.notify('invalid buffer', vim.log.levels.ERROR)
        return
    end

    vim.cmd('windo diffoff')
    local wins = vim.api.nvim_list_wins()
    if #wins < 2 then
        vim.cmd('vsplit')
    end

    wins = vim.api.nvim_list_wins()
    local left_win = wins[1]
    local right_win = wins[2]

    vim.api.nvim_win_call(left_win, function()
        vim.api.nvim_win_set_buf(left_win, left)
        vim.cmd('diffthis')
    end)

    vim.api.nvim_win_call(right_win, function()
        vim.api.nvim_win_set_buf(right_win, right)
        vim.cmd('diffthis')
    end)
    vim.api.nvim_set_current_win(right_win)
    vim.cmd('normal! gg')
    vim.cmd('normal! ]c')
end

local function handle_diff_mode(current_buf, content_before)
    vim.cmd('checktime')
    local content_after = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, content_before)
    vim.cmd('write')

    local right_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(right_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(right_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(right_buf, 'swapfile', false)

    vim.api.nvim_buf_set_name(right_buf, ' [Aider Modified]')
    vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, content_after)
    vim.api.nvim_buf_set_option(right_buf, 'readonly', true)
    vim.api.nvim_buf_set_option(right_buf, 'modifiable', false)
    diff_buf(current_buf, right_buf)
end

function M.aider_edit(opts)
    vim.cmd('write')
    local is_visual = opts and opts.range == true

    local current_file = vim.fn.expand('%:p')
    local current_buf = vim.api.nvim_get_current_buf()
    local content_before = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    local selected_text = get_visual_selection(is_visual)

    vim.ui.input({
        prompt = "> ",
        default = "",
    }, function(input)
        if input then
            local message = selected_text
            if input ~= "" then
                message = message .. "\n\nPrompt: " .. input
            end

            local cmd = build_aider_command(M.config, current_file, message)
            local width = math.floor(vim.o.columns * M.config.float_opts.width)
            local height = math.floor(vim.o.lines * M.config.float_opts.height)
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)
            local float_opts = vim.tbl_extend("force", M.config.float_opts, {
                row = row,
                col = col,
                width = width,
                height = height,
            })
            local term_buf = vim.api.nvim_create_buf(false, true)
            local term_win = vim.api.nvim_open_win(term_buf, true, float_opts)

            local term_job_id = vim.fn.termopen(cmd, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            vim.api.nvim_win_close(term_win, true)

                            vim.cmd('checktime')
                            if M.config.mode == 'diff' then
                                handle_diff_mode(current_buf, content_before)
                            end
                            vim.notify("Aider completed successfully", vim.log.levels.INFO)
                        else
                            vim.api.nvim_win_close(term_win, true)
                            vim.notify("Aider failed with code: " .. code, vim.log.levels.ERROR)
                        end
                    end)
                end
            })
            vim.cmd('startinsert')
        end
    end)
end

function M.setup(cfg)
    if not check_aider_installed() then
        vim.notify("Aider not found in PATH. Please install aider first.", vim.log.levels.ERROR)
        return
    end

    -- Merge user config with defaults
    M.config = vim.tbl_deep_extend("force", default_config, cfg or {})

    vim.api.nvim_create_user_command('AiderEdit', function(opts)
        M.aider_edit(opts)
    end, { range = true })
end

return M
