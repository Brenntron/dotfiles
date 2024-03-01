# Add ssh keys with keychain password manager
ssh-add --apple-use-keychain

export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/imagemagick@6/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="$PATH::$(yarn global bin)"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export KERL_CONFIGURE_OPTIONS="--disabled-debug --without-javac --disable-hipe --with-ssl=$(brew --prefix openssl)"
export NODE_OPTIONS="--max-old-space-size=8192"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

require "autoenv" "brew install autoenv"
require "bat" "brew install bat"
requrie "fzf" "brew install fzf"
require "gcc" "brew install gcc"

alias cat="bat"
