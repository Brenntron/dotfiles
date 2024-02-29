alias cat="batcat"
alias drun='docker run -it --network=host --device=/dev/kfd --device=/dev/dri --group-add=video --ipc=host --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v $(pwd):/pwd'

export KERL_CONFIGURE_OPTIONS="--disable-debug --disable-silent-rules --without-javac --enable-shared-zlib --enable-dynamic-ssl-lib --enable-hipe --enable-sctp --enable-smp-support --enable-threads --enable-kernel-poll --enable-wx --enable-darwin-64bit --with-ssl=/usr/local/Cellar/openssl/1.0.2p"
export SSH_AUTH_SOCK=~/.1password/agent.sock
export ZPLUG_HOME=$HOME/.zplug

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  1password
  aliases
  alias-finder
  asdf
  autoenv
  brew
  bundler
  copyfile
  copypath
  cp
  docker
  docker-compose
  fzf
  gh
  git
  gpg-agent
  rails
  ruby
  ssh-agent
  thefuck
  ubuntu
  yarn
)
