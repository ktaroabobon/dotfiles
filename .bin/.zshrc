export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/keitarowatanabe/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/keitarowatanabe/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/keitarowatanabe/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/keitarowatanabe/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
