# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

source $ZSH/oh-my-zsh.sh
source ~/code/tools/zsh-autocomplete/zsh-autocomplete.plugin.zsh

if [[ $(uname) == "Linux" ]]; then
  source ~/.config/linux/linuxbrew.zsh
else
  source ~/.config/osx/homebrew.zsh
fi

# FZF setup
export FZF_BASE="$(brew --prefix fzf)"
export FZF_DEFAULT_COMMAND='fd -H -i'
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4 --preview "cat --color=always {}" --preview-window "~3"'
source ~/.fzf.zsh

# asdf setup
source ~/.config/asdf/asdf_setup.zsh

# obsidianmd-cli completions
source ~/.config/completions/obsidianmd.zsh


# Customer syntax highlighting must come before activating zsh-syntax-highlighting
source ~/.config/tokyonight/zsh-syntax-highlighting.zsh

source $(brew --prefix)/share/antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle alias-finder
antigen bundle aliases
antigen bundle autoenv
antigen bundle bundler
antigen bundle command-not-found
antigen bundle containers
antigen bundle copybuffer
antigen bundle copyfile
antigen bundle copypath
antigen bundle cp
antigen bundle fzf
antigen bundle gh
antigen bundle git
antigen bundle gpg-agent
antigen bundle pip
antigen bundle podman
antigen bundle rails
antigen bundle rsync
antigen bundle ruby
antigen bundle ssh-agent
antigen bundle yarn
antigen bundle redxtech/zsh-kitty
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle atuinsh/atuin@main

if [[ $(uname) == "Linux" ]]; then
  source ~/.config/linux/linux_zsh_plugins.zsh
else
  source ~/.config/osx/osx_zsh_plugins.zsh
fi

antigen apply

# oh-my-posh theme
eval "$(oh-my-posh init zsh --config ~/.config/tokyonight/oh-my-posh/tokyonight_moon.omp.json)"

# Source zsh config based on operating system used.

if [[ $(uname) == "Linux" ]]; then
  source ~/.config/linux/linux.zsh
else
  source ~/.config/osx/osx.zsh
fi

# enable autocomplete function
autoload -U compinit
compinit

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export PATH="$(brew --prefix imagemagick@6)/bin:$PATH"
export PATH="$(brew --prefix openssl@3)/bin:$PATH"
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"

export PATH="$PATH::$(yarn global bin)"
export PATH="${HOME}/.local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

export XDG_CONFIG_HOME="${HOME}/.config"
export YAMLLINT_CONFIG_FILE="${XDG_CONFIG_HOME}/yamllint/config.yml"
export PRETTIERD_DEFAULT_CONFIG="~/.config/prettier/prettier.config.js"

source $(dirname $(gem which colorls))/tab_complete.sh

alias lc="colorls --dark"
alias l="colorls -l --dark"
alias ll="colorls -lA --dark"
alias la="colorls -la --dark"
alias lt="colorls -lt --dark"
alias lS="colorls -lS --dark"
alias lr="colorls --tree=5 --dark"
alias lx="colorls -lAX --dark"

alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc' # Quick access to the .zshrc file

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

alias t='tail -f'

# Command line head / tail shortcuts
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g M="| most"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g P="2>&1| pygmentize -l pytb"

alias dud='du -d 1 -h'
alias duf='du -sh *'
alias fdir='find -L . -type d | fzf > selected --height=100%'
alias ffile='find -L . -type f | fzf > selected --height=100%'

alias h='history'
alias hgrep="fc -El 0 | grep"
alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

#read documents
alias -s ps=gv
alias -s dvi=xdvi
alias -s chm=xchm
alias -s djvu=djview

#list whats inside packed file
alias -s zip="unzip -l"
alias -s rar="unrar l"
alias -s tar="tar tf"
alias -s tar.gz="echo "
alias -s ace="unace l"

alias cc='gcc'
alias CC='gcc'

# Podman Compose aliases
alias pc='podman compose'

# Set alias for dotfiles config
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# enable alias-finder
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default

alias spectral='spectral-language-server'

# enable autoenv
source $(brew --prefix autoenv)/activate.sh

# start zoxide
eval "$(zoxide init zsh)"

# kitty completeions
__kitty_complete
