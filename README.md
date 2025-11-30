# kitty-sessions

A simple bash script for managing kitty sessions in a similar way to `tmux-sessionizer` (or as close as I could get).
The script allows choosing a project directory via `fzf` and starting a kitty session for it.
It also contains a save function that allows to overwrite a running session with the current state.
Saving is not automatic yet and needs to be triggered manually.

## How it works

For each session a `<project-name>.kitty-session` file is created in the project directory.
If that file already exists the script will load the session.
Otherwise it will create a new 'empty' session with just one tab in the project's main directory.

## Requirements

The script needs `fzf` and `fd` installed on your system.
It also requires `allow_remote_control yes` to be activated in your kitty config.

## Usage

Download the script and put it somewhere.

Replace the following line in the script with paths to your own project directories.

```bash
# Set your Project paths here
# Currently only a depth of 1 is supported
KS_PATHS=(~/Projects ~/Documents)
```

Add the following mappings to your kitty config (replacing the path to the script with where you put it).

```bash
# Run the interactive fzf picker to start/load a session
map f5 launch --type=overlay-main ~/.local/bin/scripts/kitty-sessions.sh start
# Save the current session
map f6 launch --type=tab --tab-title=KS_TAB --add-to-session . --keep-focus ~/.local/bin/scripts/kitty-sessions.sh save
```

## Remarks

This is mainly for personal use and not very polished yet.
The script needs some not so nice workarounds to make kitty sessions behave in the way that I want them to.
Very likely there are some bugs and use cases I didn't think of.
The saving script is only able to save tabs that are actually part of the current kitty session.
If you spawn your tabs with `new_tab_with_cwd` it will work correctly because kitty automatically adds those to
the current session.
