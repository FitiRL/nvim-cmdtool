## nvim-cmdtool

A powerful command line tool for Neovim that provides seamless integration between the editor and terminal workflows. Execute commands, manage build tasks and interact with CLI tools without leaving your editor.

A `json` file with a list of commands is defined and parsed by this plugin. Then, the list of commands can be executed from the editor. See examples in this page.

## Features

- 🚀 Execute shell commands with real-time output
- 📋 Review logs of finished tasks
- 🔄 Quick repeat last command
- 📊 Multiple output formats (float terminal, silent)
- 💾 On-save actions

https://github.com/user-attachments/assets/389976a8-5337-4c6d-8d25-64fb0c56f10e

## Installation

### Using vim-plug

```vim
Plug 'FitiRL/nvim-cmdtool'
```

## Requirements

- telescope
- vim-floaterm


## Usage

### Basic commands

Open the command list displayed in `Telescope`:

```vim
:CMDtool
```

Review the log:

```vim
:CMDtoolLog
```

Repeat the last command:

```vim
:CMDtoolRepeat
```

## Examples

Create a `cmdtool.json` file and save it to `~/.config/nvim/` directory. Properties of objets are as follow:

- Name: The name of the task. It will be displayed in Telescope window.
- Command: The shell command to be executed in the float terminal.
- Description: A short description about what the command does. It will be displayed as well in the telescope viewer.
- Type:
    - `shell`: It will be executed in normal shell (floaterm).
    - `shell_silent`: Executed but no floaterm is open. Result is displayed as an alert.
    - `vim`: The command is executed as vim command. See example below.
    - `on_save`: Number. If 1, the command will be automatically executed when the buffer is saved.

```json
[
  {
    "name": "Git Status",
    "command": "git status",
    "description": "Show git repository status",
    "type": "shell"
  },
  {
    "name": "Git pull",
    "command": "git pull && git status",
    "description": "Pull and show status",
    "type": "shell"
  },
  {
    "name": "Git pull (silent)",
    "command": "git pull && git status",
    "description": "Pull and show status",
    "type": "shell_silent"
  },
  {
    "name": "TIG",
    "command": "tig",
    "description": "Execute tig",
    "type": "shell"
  },
  {
    "name": "Compile",
    "command": "gcc main.c -o main && ./main",
    "description": "Compile",
    "type": "shell"
  },
  {
    "name": "Silent long task",
    "command": "echo \"Doing something!...\"; sleep 7;",
    "description": "Execute long task",
    "type": "shell_silent"
  },
  {
    "name": "Toggle Line Numbers",
    "command": "set number!",
    "description": "Toggle line numbers",
    "type": "vim"
  },
]
```

### Use case

Given the previous example, the `Compile` task can be repeately executed if mapped, for example, to any shortcut:

```vim
nnoremap <Space>cc <cmd>CMDtoolRepeat<cr>
```

Now, everytime `<Space>cc` is pressed, the process is compiled. As it executes the last command, you can easily switch by choosing a new one with `CMDtool`.


