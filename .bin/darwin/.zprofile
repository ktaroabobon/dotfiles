export HOMEBREW_PREFIX="/opt/homebrew"; 
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew"; 
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"; 
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"; 
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";

# brew のパスより前に、場所ごとにアカウントを切り替えるラッパーを置く
export PATH="$HOME/.local/profile-bin:$PATH"
