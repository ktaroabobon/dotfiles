export HOMEBREW_PREFIX="/opt/homebrew"; 
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew"; 
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"; 
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"; 
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export PATH=$PATH:$HOME/.nodebrew/current/bin;
export PATH="$HOME/.poetry/bin:$PATH";

alias python='python3';
alias pip='pip3';

# Added by Toolbox App
export PATH="$PATH:/Users/keitarowatanabe/Library/Application Support/JetBrains/Toolbox/scripts"export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"
