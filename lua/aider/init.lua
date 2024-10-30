local M = {}

-- Default configuration
local default_config = {
    command = 'aider',
    -- 基本選項
    dark_mode = true,
    subtree_only = true,
    cache_prompts = true,
    no_stream = true,
    chat_language = 'zh-tw',
    sonnet = true,
}

-- Convert config to command line arguments
local function config_to_args(config)
    local args = {}

    -- Convert boolean options
    if config.dark_mode then table.insert(args, '--dark-mode') end
    if config.subtree_only then table.insert(args, '--subtree-only') end
    if config.cache_prompts then table.insert(args, '--cache-prompts') end
    if config.no_stream then table.insert(args, '--no-stream') end
    if config.sonnet then table.insert(args, '--sonnet') end

    -- Convert value options
    if config.chat_language then
        table.insert(args, '--chat-language')
        table.insert(args, config.chat_language)
    end

    return args
end

-- Build complete aider command
local function build_aider_command(config, file_path, message)
    local args = config_to_args(config)
    local cmd = config.command

    -- 加入固定參數
    table.insert(args, '--chat-mode=code')
    table.insert(args, '--no-auto-commits')

    -- 加入檔案參數
    table.insert(args, '--file')
    table.insert(args, file_path)

    -- 加入 message 參數
    if message then
        table.insert(args, '--message')
        table.insert(args, string.format("%q", message))
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

-- 獲取 visual 選中的文字
local function get_visual_selection()
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

-- 主要功能函數
function M.run_aider()
    -- 獲取當前檔案路徑和 buffer
    local current_file = vim.fn.expand('%:p')
    local current_buf = vim.api.nvim_get_current_buf()

    -- 保存當前 buffer 內容到暫存檔
    local temp_file = vim.fn.tempname()
    vim.fn.writefile(vim.api.nvim_buf_get_lines(current_buf, 0, -1, false), temp_file)

    -- 獲取選中的文字
    local selected_text = get_visual_selection()

    -- 彈出輸入框讓使用者輸入 prompt
    vim.ui.input({
        prompt = "Enter your prompt: ",
        default = "",
    }, function(input)
        if input then
            -- 組合 selected_text 和 prompt
            local message = selected_text
            if input ~= "" then
                message = message .. "\n\nPrompt: " .. input
            end

            -- 使用修改後的 build_aider_command
            local cmd = build_aider_command(M.config, current_file, message)
            
            -- 除錯輸出
            vim.notify("Running command: " .. cmd, vim.log.levels.INFO)

            -- 計算浮動視窗的尺寸和位置
            local width = math.floor(vim.o.columns * 0.8)
            local height = math.floor(vim.o.lines * 0.8)
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)

            -- 創建浮動視窗的配置
            local float_opts = {
                relative = 'editor',
                row = row,
                col = col,
                width = width,
                height = height,
                style = 'minimal',
                border = 'rounded',
                title = ' Aider ',
                title_pos = 'center',
            }

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
                            
                            -- 保存 aider 修改後的內容
                            local modified_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
                            
                            -- 還原原始檔案內容並寫入
                            local original_content = vim.fn.readfile(temp_file)
                            vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, original_content)
                            vim.cmd('write')  -- 寫入檔案
                            vim.cmd('edit!') -- 重新讀取檔案
                            
                            -- 在右側新的分割視窗中顯示修改後的內容
                            vim.cmd('botright vsplit')  -- 在右側分割
                            local new_buf = vim.api.nvim_create_buf(true, false)
                            vim.api.nvim_win_set_buf(0, new_buf)
                            vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, modified_lines)
                            
                            -- 設定新 buffer 為唯讀
                            vim.bo[new_buf].readonly = true
                            vim.bo[new_buf].modifiable = false
                            
                            -- 設定兩個視窗為 diff 模式
                            vim.cmd('windo diffthis')

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
function M.setup(opts)
    if not check_aider_installed() then
        vim.notify("Aider not found in PATH. Please install aider first.", vim.log.levels.ERROR)
        return
    end

    -- Merge user config with defaults
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_user_command('AiderEdit', function()
        M.run_aider()
    end, { range = true })
end

return M
