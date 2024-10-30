local M = {}

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
  
  -- 創建新的 buffer 顯示結果
  vim.cmd('vnew')
  local buf = vim.api.nvim_get_current_buf()
  
  -- 執行 aider 命令
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
      end
    end,
    stdin_data = selected_text
  })
  
  -- 設置 diff mode
  vim.cmd('windo diffthis')
end

-- 設置命令
function M.setup()
  vim.api.nvim_create_user_command('AiderEdit', function()
    M.run_aider()
  end, { range = true })
end

return M
