# fzf config
# ---------
export FZF_BASE="$(brew --prefix fzf)"
export FZF_DEFAULT_COMMAND='fd -H -i'
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4 --preview "cat --color=always {}" --preview-window "~3"'
export FZF_PATH="${FZF_BASE}/bin"

if [[ ! "$PATH" == *$FZF_PATH* ]]; then
  export PATH="${PATH:+${PATH}:}${FZF_PATH}"
fi

# Auto-completion
# ---------------
source ${FZF_BASE}/shell/completion.zsh

# Key bindings
# ------------
source ${FZF_BASE}/shell/key-bindings.zsh
