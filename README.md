# nvim-aider

A Neovim plugin that integrates [Aider](https://github.com/paul-gauthier/aider), an AI coding assistant, directly into your editor.

## Features

- Visual selection based AI code editing
- Split window diff view of changes
- Floating terminal window for Aider interaction
- Customizable window appearance
- Preserves original file until changes are confirmed

## Requirements

- Neovim >= 0.10.2
- [Aider](https://github.com/paul-gauthier/aider) installed and available in PATH
- Python environment with Aider dependencies

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "ddzero2c/aider.nvim",
    opts = {
        -- Optional custom configuration
    },
}
```

## Configuration

Default configuration with all available options:

```lua
require("aider").setup({
    command = 'aider',           -- Path to aider command
    dark_mode = true,           -- Use dark mode
    subtree_only = true,        -- Only edit subtree of selected files
    cache_prompts = true,       -- Cache prompts for faster responses
    no_stream = true,           -- Disable streaming responses
    chat_language = 'en',       -- Chat interface language
    sonnet = true,              -- Use GPT-4 for better responses
    -- Floating window options
    float_opts = {
        relative = 'editor',
        width = 0.8,            -- 80% of editor width
        height = 0.8,           -- 80% of editor height
        style = 'minimal',
        border = 'rounded',
        title = ' Aider ',
        title_pos = 'center',
    },
})
```

## Usage

1. Select code in visual mode
2. Run `:AiderEdit`
3. Enter your prompt in the input box
4. Review changes in the diff view
5. Save or discard changes as needed

## Recommended Keymaps

Add to your Neovim configuration:

```lua
-- Basic keymap for visual mode
vim.keymap.set('v', 'ga', ':AiderEdit<CR>', { noremap = true, silent = true })
```

## How It Works

1. When triggered, the plugin:
   - Captures the visually selected code
   - Opens a floating terminal window
   - Runs Aider in chat mode with the selected code
   - Shows changes in a split diff view

2. The diff view shows:
   - Original file on the left
   - Proposed changes on the right
   - You can review and decide to accept or reject changes

## License

MIT License
