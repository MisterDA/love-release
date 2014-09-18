# love-release Bash completion

_love-release()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-l"
    opts="$opts -w --win-icon"
    opts="$opts -d --deb-icon --deb-package-version --deb-maintainer-name --maintainer-email --deb-package-name"
    opts="$opts -a --activity --apk-package-version --apk-maintainer-name --apk-package-name --update-android"
    opts="$opts -m --osx-icon --osx-maintainer-name"
    opts="$opts -h -n -r -v -x --config --homepage --description --clean --help"

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
complete -F _love-release love-release

