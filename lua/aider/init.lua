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

-- Convert config to command line arguments
local function config_to_args(config)
    local args = {}

    table.insert(args, '--chat-mode=code')
    table.insert(args, '--no-auto-commits')
    table.insert(args, '--subtree-only')
    table.insert(args, '--cache-prompts')
    table.insert(args, '--no-stream')
    -- Model handling
    if config.model then
        local flag = model_flags[config.model]
        if flag then
            table.insert(args, flag)
        else
            -- For undefined models, use --model parameter
            table.insert(args, '--model')
            table.insert(args, config.model)
        end
    end

    return args
end

-- Build complete aider command
local function build_aider_command(config, file_path, message)
    local args = config_to_args(config)
    local cmd = config.command

    -- 加入檔案參數
    table.insert(args, '--file')
    table.insert(args, file_path)

    -- Add message parameter with proper escaping
    if message then
        table.insert(args, '--message')
        -- Escape special characters and wrap in single quotes
        local escaped_message = message:gsub("'", "'\\''") -- Escape single quotes
        table.insert(args, "'" .. escaped_message .. "'")
    end

    -- 組合完整命令
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
        -- 在 normal mode 下獲取整個文件內容
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    end

    -- visual mode 邏輯
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    -- 處理單行選擇的情況
    if #lines == 1 then
        lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
        -- 處理首尾行
        lines[1] = string.sub(lines[1], start_pos[3])
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end

    return table.concat(lines, "\n")
end

-- 處理 diff 模式
local function handle_diff_mode(current_buf, temp_file)
    -- 創建左側 buffer 來顯示原始內容
    local original_buf = vim.api.nvim_create_buf(false, true)

    -- 設置原始 buffer 的屬性
    vim.api.nvim_buf_set_option(original_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(original_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(original_buf, 'swapfile', false)

    -- 設置 buffer 名稱
    local filename = vim.fn.expand('%:t')
    vim.api.nvim_buf_set_name(original_buf, filename .. ' [Original]')

    -- 在左側開啟原始內容
    vim.cmd('topleft vsplit')
    vim.api.nvim_win_set_buf(0, original_buf)

    -- 設置原始內容
    local original_content = vim.fn.readfile(temp_file)
    vim.api.nvim_buf_set_lines(original_buf, 0, -1, false, original_content)

    -- 設定為唯讀
    vim.api.nvim_buf_set_option(original_buf, 'readonly', true)
    vim.api.nvim_buf_set_option(original_buf, 'modifiable', false)

    -- 重新讀取當前檔案以獲取最新修改
    vim.cmd('checktime')

    -- 設定兩個視窗為 diff 模式
    vim.cmd('windo diffthis')
end

-- 主要功能函數
function M.aider_edit(opts)
    -- 檢查是否為 visual mode
    local is_visual = opts and opts.range == true

    -- 獲取當前檔案路徑和 buffer
    local current_file = vim.fn.expand('%:p')
    local current_buf = vim.api.nvim_get_current_buf()

    -- 保存當前 buffer 內容到暫存檔
    local temp_file = vim.fn.tempname()
    vim.fn.writefile(vim.api.nvim_buf_get_lines(current_buf, 0, -1, false), temp_file)

    -- 獲取選中的文字，傳入 is_visual 參數
    local selected_text = get_visual_selection(is_visual)

    -- 彈出輸入框讓使用者輸入 prompt
    vim.ui.input({
        prompt = "> ",
        default = "",
    }, function(input)
        if input then
            -- 組合 selected_text 和 prompt
            local message = selected_text
            if input ~= "" then
                message = message .. "\n\nPrompt: " .. input
            end

            -- 在執行 aider 前先存檔
            vim.cmd('write')

            -- 使用修改後的 build_aider_command
            local cmd = build_aider_command(M.config, current_file, message)

            -- 計算浮動視窗的尺寸和位置
            local width = math.floor(vim.o.columns * M.config.float_opts.width)
            local height = math.floor(vim.o.lines * M.config.float_opts.height)
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)

            -- 創建浮動視窗的配置
            local float_opts = vim.tbl_extend("force", M.config.float_opts, {
                row = row,
                col = col,
                width = width,
                height = height,
            })

            -- 創建浮動視窗
            local term_buf = vim.api.nvim_create_buf(false, true)
            local term_win = vim.api.nvim_open_win(term_buf, true, float_opts)

            -- 在終端機中執行 aider
            local term_job_id = vim.fn.termopen(cmd, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            -- 關閉浮動視窗
                            vim.api.nvim_win_close(term_win, true)

                            -- 重新讀取檔案以獲取 aider 的修改
                            vim.cmd('checktime')

                            -- 根據模式處理修改
                            if M.config.mode == 'diff' then
                                handle_diff_mode(current_buf, temp_file)
                            end

                            vim.notify("Aider completed successfully", vim.log.levels.INFO)
                        else
                            -- 關閉浮動視窗
                            vim.api.nvim_win_close(term_win, true)
                            vim.notify("Aider failed with code: " .. code, vim.log.levels.ERROR)
                        end
                    end)
                end
            })

            -- 自動進入插入模式
            vim.cmd('startinsert')
        end
    end)
end

-- 設置命令
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
