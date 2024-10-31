# aider.nvim

A Neovim plugin that integrates [Aider](https://github.com/paul-gauthier/aider), an AI coding assistant, directly into your editor.

Aider uses a smart repository mapping system to understand your entire codebase:

- **Repository Map**: Aider creates a concise map of your git repository that includes:
  - Important classes and functions
  - Type information and call signatures
  - Key relationships between different parts of code

- **Smart Context**: When you make an edit request:
  - Aider analyzes the repository structure
  - Identifies relevant code across all files
  - Provides the AI with necessary context for intelligent edits

- **Dynamic Optimization**:
  - Automatically adjusts the amount of context based on the chat state
  - Focuses on the most referenced and important code parts
  - Ensures efficient use of the AI's context window

This means Aider can make informed code changes that respect your existing codebase structure and conventions, even when modifying a single file.

## Requirements

- Neovim >= 0.10.2
- [Aider](https://aider.chat/docs/install.html) installed and available in PATH

Before using aider.nvim, you need to set up your API key:

1. For Anthropic models (default):
   ```bash
   export ANTHROPIC_API_KEY=your_api_key_here
   ```
2. For OpenAI models:
   ```bash
   export OPENAI_API_KEY=your_api_key_here
   ```


You can add these environment variables to your shell's startup file (e.g., `.bashrc`, `.zshrc`) or use a tool like [direnv](https://direnv.net/) to manage them.

Default model: `sonnet`, see more models [here](https://aider.chat/docs/llms.html)


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
    model = 'sonnet',            -- AI model to use
    mode = 'diff',               -- Edit mode: 'diff' or 'inline'
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


### Mode Options

- `diff`: Shows changes in a split diff view (default)
  - Left window: Original file
  - Right window: Modified version
  - Use this mode to review changes
- `inline`: Directly applies changes to the current file
  - Modifies file content immediately
  - No diff view shown
  - Use this mode for faster editing workflow

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
vim.keymap.set({'v', 'n'}, 'ga', ':AiderEdit<CR>', { noremap = true, silent = true })
```

## License

MIT License
