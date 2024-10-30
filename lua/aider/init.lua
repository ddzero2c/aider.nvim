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

            -- 開啟終端機視窗
            vim.cmd('botright split')
            local term_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_win_set_buf(0, term_buf)
            
            -- 設定終端機高度
            vim.api.nvim_win_set_height(0, 15)
            
            -- 在終端機中執行 aider
            local term_job_id = vim.fn.termopen(cmd, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            -- 重新讀取檔案
                            vim.cmd('checktime')

                            -- 關閉終端機視窗
                            vim.cmd('quit')

                            -- 開啟 diff 視窗
                            vim.cmd('diffthis')
                            vim.cmd('vsplit ' .. temp_file)
                            vim.cmd('diffthis')

                            -- 設定暫存檔 buffer 為唯讀
                            vim.bo.readonly = true
                            vim.bo.modifiable = false

                            vim.notify("Aider completed successfully", vim.log.levels.INFO)
                        else
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
