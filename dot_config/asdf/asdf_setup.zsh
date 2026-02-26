_ASDF_PREFIX="$(brew --prefix asdf)"
ASDF_COMPLETIONS="${_ASDF_PREFIX}/share/zsh/site-functions"

export ASDF_DATA_DIR="${HOME}/.asdf"
export PATH="$ASDF_DATA_DIR/shims:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

unset _ASDF_PREFIX

fpath+=("$ASDF_COMPLETIONS")
autoload -Uz _asdf
compdef _asdf asdf

export ASDF_CONFIG_FILE="${HOME}/.config/asdf/.asdfrc"
. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh

# Set JAVA_HOME
. ~/.asdf/plugins/java/set-java-home.zsh
