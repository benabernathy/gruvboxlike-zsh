# gruvboxlike.zsh-theme
# Gruvbox-dark powerline theme for oh-my-zsh
# Requires a Nerd Font or Powerline-patched font
#
# Left : [user@host] > [directory] > [git branch]
# Right: [elapsed] < [exit code]

autoload -Uz add-zsh-hook
setopt PROMPT_SUBST

# ── Gruvbox dark 256-colour palette ──────────────────────────────
_GRV_FG=223      # #ebdbb2  cream — text on coloured segments
_GRV_TAUPE=243   # #7c6f64  user@host segment (gruvbox bg4)
_GRV_BLUE=66     # #458588  directory segment
_GRV_YELLOW=172  # #d79921  git branch segment
_GRV_AQUA=72     # #689d6a  elapsed-time segment
_GRV_GREEN=100   # #98971a  exit-ok segment
_GRV_RED=167     # #fb4934  exit-err segment

# ── Powerline glyphs (Nerd Font / Powerline-patched font required) ─
_PL_ARROW=$'\ue0b0'    # U+E0B0  solid right-arrow   (left-prompt separator)
_PL_BSLASH=$'\ue0b2'   # U+E0B2  solid left-arrow = '<' (right-prompt separator)

# ── Runtime state (set in precmd, used when building prompts) ────
_GRV_ELAPSED_STR="0s"
_GRV_EXIT_CODE=0

# ── Segment helpers ───────────────────────────────────────────────

_grv_lseg() {
  local bg=$1 bgnext=$2 content=$3
  local out="%K{$bg}%F{$_GRV_FG} ${content} "
  if [[ -n $bgnext ]]; then
    out+="%K{$bgnext}%F{$bg}${_PL_ARROW}"
  else
    out+="%k%f"
  fi
  print -rn -- "$out"
}

_grv_rseg() {
  local bgprev=$1 bg=$2 content=$3
  local out=""
  if [[ -n $bgprev ]]; then
    out+="%K{$bgprev}%F{$bg}${_PL_BSLASH}%K{$bg}%F{$_GRV_FG}"
  else
    out+="%K{$bg}%F{$_GRV_FG}"
  fi
  out+=" ${content} "
  print -rn -- "$out"
}

# ── Git info — direct git calls ───────────────────────────────────
_grv_git_info() {
  local ref
  ref=$(command git symbolic-ref HEAD 2>/dev/null) || \
  ref=$(command git rev-parse --short HEAD 2>/dev/null) || return 1
  local branch="${ref#refs/heads/}"
  local dirty=""
  [[ -n $(command git status --porcelain 2>/dev/null) ]] && dirty=" ✗"
  printf '%s' "${branch}${dirty}"
}

# ── Prompt builders ──────────────────────────────────────────────

_grv_build_prompt() {
  local git_info
  git_info=$(_grv_git_info)
  local p=""
  if [[ -n $git_info ]]; then
    p+=$(_grv_lseg $_GRV_TAUPE $_GRV_BLUE   "%n@%m")
    p+=$(_grv_lseg $_GRV_BLUE  $_GRV_YELLOW "%~")
    p+=$(_grv_lseg $_GRV_YELLOW ""          "$git_info")
  else
    p+=$(_grv_lseg $_GRV_TAUPE $_GRV_BLUE "%n@%m")
    p+=$(_grv_lseg $_GRV_BLUE  ""         "%~")
  fi
  print -rn -- "$p "
}

_grv_build_rprompt() {
  local exit_bg exit_label
  if [[ $_GRV_EXIT_CODE -eq 0 ]]; then
    exit_bg=$_GRV_GREEN
    exit_label="✓"
  else
    exit_bg=$_GRV_RED
    exit_label="✗ $_GRV_EXIT_CODE"
  fi
  local r=""
  r+=$(_grv_rseg ""         $_GRV_AQUA "$_GRV_ELAPSED_STR")
  r+=$(_grv_rseg $_GRV_AQUA $exit_bg   "$exit_label")
  r+="%k%f"
  print -rn -- "$r"
}

# ── Hooks ────────────────────────────────────────────────────────

_gruvlike_preexec() {
  _gruvlike_cmd_start=$SECONDS
}

_gruvlike_precmd() {
  local exit_code=$?
  _GRV_EXIT_CODE=$exit_code

  if [[ -n $_gruvlike_cmd_start ]]; then
    local elapsed=$(( SECONDS - _gruvlike_cmd_start ))
    unset _gruvlike_cmd_start
  else
    local elapsed=0
  fi

  if   (( elapsed >= 3600 )); then
    _GRV_ELAPSED_STR="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m$(( elapsed % 60 ))s"
  elif (( elapsed >= 60 )); then
    _GRV_ELAPSED_STR="$(( elapsed / 60 ))m$(( elapsed % 60 ))s"
  else
    _GRV_ELAPSED_STR="${elapsed}s"
  fi

  PROMPT=$(_grv_build_prompt)
  RPROMPT=$(_grv_build_rprompt)
}

_gruvlike_chpwd() {
  PROMPT=$(_grv_build_prompt)
}

add-zsh-hook preexec _gruvlike_preexec
add-zsh-hook precmd  _gruvlike_precmd
add-zsh-hook chpwd   _gruvlike_chpwd

# Guarantee our precmd runs last so no async git plugin can overwrite PROMPT
precmd_functions=("${(@)precmd_functions:#_gruvlike_precmd}" _gruvlike_precmd)
