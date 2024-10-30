local M = {}

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
  -- 獲取當前檔案路徑
  local current_file = vim.fn.expand('%:p')
  -- 獲取選中的文字
  local selected_text = get_visual_selection()
  
  -- 創建臨時檔案存放 aider 結果
  local temp_file = vim.fn.tempname()
  
  -- 構建 aider 命令
  local cmd = string.format("aider /add %s", current_file)
  
  -- 保存當前 buffer 和窗口
  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()

  -- 創建新的 buffer 顯示結果
  vim.cmd('vnew')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_name(buf, 'Aider Result')
  
  -- 執行 aider 命令
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 1 then
        local output_lines = {}
        for _, line in ipairs(data) do
          if not line:match("^%s*$") and
             not line:match("^Aider") and
             not line:match("^%[") then
            table.insert(output_lines, line)
          end
        end
        if #output_lines > 0 then
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, output_lines)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.notify("Aider error: " .. vim.inspect(data), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("Aider process exited with code: " .. code, vim.log.levels.ERROR)
      end
      -- 設置 diff mode
      vim.cmd('windo diffthis')
    end,
    stdin_data = selected_text
  })
end

-- 設置命令
function M.setup()
  if not check_aider_installed() then
    vim.notify("Aider not found in PATH. Please install aider first.", vim.log.levels.ERROR)
    return
  end
  
  vim.api.nvim_create_user_command('AiderEdit', function()
    M.run_aider()
  end, { range = true })
end

return M
