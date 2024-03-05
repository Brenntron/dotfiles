# Add ssh keys with keychain password manager
ssh-add --apple-use-keychain

export KERL_CONFIGURE_OPTIONS="--disabled-debug --without-javac --disable-hipe --with-ssl=$(brew --prefix openssl)"
export NODE_OPTIONS="--max-old-space-size=8192"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

alias cat="bat"
