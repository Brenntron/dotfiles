# fzf config
# ---------
export FZF_PATH="${FZF_BASE}/bin"
if [[ ! "$PATH" == *$FZF_PATH* ]]; then
  export PATH="${PATH:+${PATH}:}${FZF_PATH}"
fi

# Auto-completion
# ---------------
source "${$FZF_BASE}/shell/completion.zsh"

# Key bindings
# ------------
source "${$FZF_BASE}/shell/key-bindings.zsh"
