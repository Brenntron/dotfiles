export KERL_CONFIGURE_OPTIONS="--disable-debug --disable-silent-rules --without-javac --enable-shared-zlib --enable-dynamic-ssl-lib --enable-hipe --enable-sctp --enable-smp-support --enable-threads --enable-kernel-poll --enable-wx --enable-darwin-64bit --with-ssl=/usr/local/Cellar/openssl/1.0.2p"
export SSH_AUTH_SOCK=~/.1password/agent.sock

require "batcat" "sudo apt update;sudo apt install bat -y"
require "fnt" "sudo apt update;sudo apt install fnt -y"
require "find" "sudo apt update;sudo apt install findutils"
require "fzf" "sudo apt update;sudo apt install fzf -y"
require "gcc" "sudo apt update;sudo apt install build-essential -y"
require "oh-my-posh" "sudo apt update;sudo apt install oh-my-posh -y"

alias cat="batcat"
