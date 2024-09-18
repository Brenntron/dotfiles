_ASDF_PREFIX="$(brew --prefix asdf)"
ASDF_COMPLETIONS="${_ASDF_PREFIX}/share/zsh/site-functions"

source "${_ASDF_PREFIX}/libexec/asdf.sh"

unset _ASDF_PREFIX

fpath+=("$ASDF_COMPLETIONS")
autoload -Uz _asdf
compdef _asdf asdf

export ASDF_CONFIG_FILE="${HOME}/.config/asdf/.asdfrc"
