ssh-add --apple-use-keychain

# Use homebrew installed gcc
alias cc='gcc'
alias CC='gcc'

if [ -x "$(command -v cat)" ]; then
  alias cat="bat"
fi

. /opt/homebrew/opt/asdf/libexec/asdf.sh

export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/imagemagick@6/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="$PATH::$(yarn global bin)"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export KERL_CONFIGURE_OPTIONS="--disabled-debug --without-javac --disable-hipe --with-ssl=$(brew --prefix openssl)"
# export LDFLAGS="-L/opt/homebrew/opt/llvm@13/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm@13/include"
export NODE_OPTIONS="--max-old-space-size=8192"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export ZPLUG_HOME=/usr/local/opt/zplug

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

source "$(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"