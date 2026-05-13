# Add local paths
if [ "`id -u`" -eq 0 ]; then
    export PATH="/usr/local/sbin:/usr/local/bin:${PATH}"
else
    export PATH="/usr/local/bin:${PATH}"
fi
if [ -d "${HOME}/bin" ]; then
    export PATH="${HOME}/bin:${PATH}"
fi

# Set default prompt
if [ "$PS1" ]; then
    if [ "`id -u`" -eq 0 ]; then
        export PS1='\u@\h# '
    else
        export PS1='\u@\h$ '
    fi
fi

# Set terminal size
eval `resize`
