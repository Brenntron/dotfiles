export KERL_CONFIGURE_OPTIONS="--disable-debug --disable-silent-rules --without-javac --enable-shared-zlib --enable-dynamic-ssl-lib --enable-hipe --enable-sctp --enable-smp-support --enable-threads --enable-kernel-poll --enable-wx --enable-darwin-64bit --with-ssl=/usr/local/Cellar/openssl/1.0.2p"
export SSH_AUTH_SOCK=~/.1password/agent.sock

require "autoenv" "npm install -g '@hyerupcall/autoenv'"
require "batcat" "sudo apt update;sudo apt install bat -y"
require "fzf" "sudo apt update;sudo apt install fzf -y"
require "gcc" "sudo apt update;sudo apt install build-essential -y"

alias cat="batcat"
