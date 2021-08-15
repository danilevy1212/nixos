
# TODO Analyze the plugins, and the very simple ones, replicate by hand.
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
    "sh",
    "readable-traceback"
    # "pipeliner" TODO,
    # "starship" TODO May be a bit much
    # "vi_prompt" TODO https://github.com/t184256/xontrib-prompt-vi-mode/blob/master/xontrib/prompt_vi_mode.xsh
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
$MOUSE_SUPPORT = False
$VI_MODE = True
$XONSH_AUTOPAIR = True
$ENABLE_ASYNC_PROMPT = True
$COMPLETION_IN_THREAD = True
$HISTCONTROL='ignoredups'
$MULTILINE_PROMPT=' '
$XONSH_CAPTURE_ALWAYS=False

# Readable Traceback
$READABLE_TRACE_STRIP_PATH_ENV = True
$READABLE_TRACE_REVERSE = True

## Theme NORD TODO Scope guard this.
from xonsh.tools import register_custom_style
from pygments.styles import get_style_by_name

THEME_NAME="nord"
nord_pygments = get_style_by_name(THEME_NAME)
# TODO Missing the normal colors
# TODO https://github.com/dyuri/xontrib-termcolors,
nord_base = {} # TODO Add the nord normal colors here.
nord_style = nord_base | dict((str(k), v) for k,v in nord_pygments.styles.items())
nord_style_overrides = dict((str(k), v) for k,v in nord_pygments.style_overrides.items())

register_custom_style(THEME_NAME, nord_style)

$XONSH_COLOR_STYLE = THEME_NAME
$XONSH_STYLE_OVERRIDES = nord_style_overrides

# Prompt
$PROMPT_FIELDS['prompt_end'] = '@'

## aliases
aliases['rm'] = 'rm -i'
aliases['cp'] = ['rsync', '--progress', '--recursive', '--archive']
aliases['mv'] = ['rsync', '--progress', '--recursive', '--remove-source-files']
aliases['mkdir'] = 'mkdir -p'
aliases['k']='kubectl'
aliases['et']=['emacsclient', '-nw', '-a', 'nvim']
aliases['vim']='nvim'

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

# neovim
$EDITOR='nvim'
$ALTERNATIVE_EDITOR=''

# Lastly, the glint!
neofetch
