# aider.nvim

A Neovim plugin that integrates [Aider](https://github.com/paul-gauthier/aider), an AI coding assistant, directly into your editor.

Aider uses a smart repository mapping system to understand your entire codebase:

## Motivation

While I primarily use Aider in the terminal, I found that making simple code edits through the terminal wasn't always the most convenient approach.
I wanted a more seamless way to integrate Aider's capabilities directly into my Neovim workflow, especially for quick, single-file modifications.

What makes this plugin particularly effective is that it leverages Aider's understanding of the entire git repository.
When making changes, Aider maintains awareness of your codebase's context, resulting in more precise and contextually appropriate modifications.

I've designed the plugin to open Aider's changes in diff mode,
allowing me to navigate between modifications using `]c` and `[c`,
and apply or reject changes with `do` and `dp` respectively.
For more complex operations, I still prefer using Aider in the terminal, but for my daily editing needs, this setup works perfectly.

As a minimalist, I'm constantly exploring better ways to use Aider within Neovim,
aiming for better integration with native Neovim functionality.
After searching extensively and not finding a plugin that matched my specific needs,
I create this one. It's still somewhat experimental, and I welcome any suggestions or ideas for improvement.


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
