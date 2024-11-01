# aider.nvim

A Neovim plugin that integrates [Aider](https://github.com/paul-gauthier/aider), an AI coding assistant, directly into your editor.

## Motivation

While Aider is great in the terminal, making one-file code edits could be more convenient.
This plugin integrates Aider directly into Neovim, displaying changes in diff mode for easy move with `]c`, `[c`, and appply changes with `dp`.

For complex tasks, terminal Aider remains preferred, but this streamlines daily edits.
The plugin leverages Aider's understanding of your git repository context for more precise modifications.

Created after finding no existing solutions that matched these needs. Still experimental and open to improvements.


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

See more models [here](https://aider.chat/docs/llms.html)

### Mode Options

- `diff`: Shows changes in a split diff view (default)
  - Left window: Original
  - Right window: Aider's modifications
  - Use `]c` and `[c` to navigate between modifications
  - Use `dp` to apply changes
- `inline`: Directly applies changes to the current file
  - Modifies file content immediately
  - No diff view shown
  - Use this mode for faster editing workflow, ideal for users who use [mini.nvim](https://github.com/echasnovski/mini.nvim)

### Recommended Keymaps

Add to your Neovim configuration:

```lua
-- Basic keymap for visual mode
vim.keymap.set({'v', 'n'}, 'ga', ':AiderEdit<CR>', { noremap = true, silent = true })
```


## Usage

1. Select code in visual mode
2. Run `:AiderEdit`
3. Enter your prompt in the input box
4. Review changes in the diff view
5. Save or discard changes as needed

## License

MIT License
