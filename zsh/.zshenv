typeset -U PATH path
path=("$HOME/.local/bin" "$path[@]")
export PATH
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
