_ASDF_PREFIX="$(brew --prefix asdf)"
export ASDF_DIR="${_ASDF_PREFIX}/libexec"
ASDF_COMPLETIONS="${_ASDF_PREFIX}/share/zsh/site-functions"

source "$ASDF_DIR/asdf.sh"

unset _ASDF_PREFIX

fpath+=("$ASDF_COMPLETIONS")
autoload -Uz _asdf
compdef _asdf asdf

export ASDF_CONFIG_FILE="${HOME}/.config/asdf/.asdfrc"
