# Handle Mac platforms
CPU=$(uname -p)
if [[ "$CPU" == "arm" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    alias oldbrew=/usr/local/bin/brew
else
    export PATH="/usr/local/bin:$PATH"
fi

ssh-add --apple-use-keychain

export ZPLUG_HOME=/usr/local/opt/zplug


# Use homebrew installed gcc
alias cc='gcc'

if [ -x "$(command -v cat)" ]; then
  alias cat="bat"
fi

export CPPFLAGS="-I/usr/local/opt/llvm@13/include"
export KERL_CONFIGURE_OPTIONS="--disabled-debug --without-javac --disable-hipe --with-ssl=$(brew --prefix openssl)"
export LDFLAGS="-L/usr/local/opt/llvm@13/lib/c++ -Wl,-rpath,/usr/local/opt/llvm@13/lib/c++"
export NODE_OPTIONS="--max-old-space-size=8192"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/openssl@3/bin:$PATH"
export PATH="/usr/local/opt/llvm@13/bin:$PATH" export RUBY_CONFIGURE_OPTS="--with-libyaml-dir=$(brew --prefix libyaml) --with-openssl-dir=$(brew --prefix openssl@3)"
export PATH="$PATH::$(yarn global bin)"
source "$(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

