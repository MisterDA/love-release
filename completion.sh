# love-release Bash completion

_love-release()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="-L -a -d -e -h -i -l -p -r -t -u -v -x --author --clean --description --email --exclude --help --icon --love --pkg --release --title --url --version"

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
complete -f -F _love-release love-release

