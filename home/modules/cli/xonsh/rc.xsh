# ENV OPTIONS (https://xon.sh/envvars.html)
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

# Theme
from xonsh.tools import register_custom_style
from pygments.styles import get_style_by_name
THEME_NAME="nord"
nord_pygments = get_style_by_name(THEME_NAME)
nord_style = nord_pygments.styles
nord_style.update(nord_pygments.style_overrides)
register_custom_style(THEME_NAME, nord_style)
$XONSH_COLOR_STYLE = THEME_NAME

# aliases
# HACK NOTE Recursive aliases dont work :(,  (will be fixed in next release)
def _my_ssh(args):
    with ${...}.swap(term="xterm-256color"):
        @([$(sh -c 'which ssh').strip()] + list(args))

aliases['ssh']=_my_ssh

# xonstribs
XONTRIBS=[
    "jedi",
    "coreutils",
    "prompt_ret_code",
    "distributed",
    "pdb",
    "bashisms",
    "whole_word_jumping",
    "vox",
    "xog",
]

for contrib in XONTRIBS:
    xontrib load @(contrib)

# Lastly, the glint!
neofetch
