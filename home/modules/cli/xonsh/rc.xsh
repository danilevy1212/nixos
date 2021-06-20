## xonstribs
XONTRIBS=[
    "jedi",
    "coreutils",
    "prompt_ret_code",
    "distributed",
    "pdb",
    "whole_word_jumping",
    "vox",
    "xog",
    "z",
    "argcomplete",
    "fzf-widgets",
    "prompt_bar",
    "sh",
    # "pipeliner" TODO,
    # "starship" TODO
]

# TODO background load? BIGGEST stopper.
for contrib in XONTRIBS:
    xontrib load @(contrib)

## ENV OPTIONS (https://xon.sh/envvars.html)
$XONSH_SHOW_TRACEBACK = True
$AUTO_CD = True
$COMPLETIONS_CONFIRM = True
$DOTGLOB = True
$VC_GIT_INCLUDE_UNTRACKED = True
$AUTO_SUGGEST_IN_COMPLETIONS = True
$MOUSE_SUPPORT = True
$VI_MODE = True
$XONSH_AUTOPAIR = True
$ENABLE_ASYNC_PROMPT = True # NOTE Maybe not
$COMPLETION_IN_THREAD = True
$HISTCONTROL='ignoredups'

## Theme NORD
from xonsh.tools import register_custom_style
from pygments.styles import get_style_by_name

THEME_NAME="nord"
nord_pygments = get_style_by_name(THEME_NAME)
nord_style = nord_pygments.styles
nord_style.update(nord_pygments.style_overrides)
register_custom_style(THEME_NAME, nord_style)
$XONSH_COLOR_STYLE = THEME_NAME

## aliases
aliases['rm'] = 'rm -i'
aliases['cp'] = ['rsync', '--progress', '--recursive', '--archive']
aliases['mkdir'] = 'mkdir -p'

# Run http server in the current directory.
aliases['http-here'] = 'python3 -m http.server'

# HACK NOTE Recursive aliases don't work.
def _ssh(args):
    sh -c @(f'TERM="xterm-256color" ssh {" ".join(args) if args != [] else " "}')

aliases['ssh'] = _ssh

## Plugins
# fzf
# Keybinds
$fzf_history_binding = "c-r"  # Ctrl+R
$fzf_ssh_binding = "c-s"      # Ctrl+S
$fzf_file_binding = "c-t"      # Ctrl+T
$fzf_dir_binding = "c-g"      # Ctrl+G

# Commands
$fzf_find_command = "fd"
$fzf_find_dirs_command = "fd -t d"

# Remove color escape codes.
$FZF_DEFAULT_OPTS='--ansi'

# Z Cache
$_Z_DATA = $XDG_DATA_HOME + '/z'

# Lastly, the glint!
neofetch
