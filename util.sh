#!/bin/bash

# debug mode
# verbose=3
# Author: Awada.Z

# (): string
version() {
    echo 1.0.3
}

# (): string
_SCRIPTPATH() {
    echo "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
}

_UTILDATE() {
    echo $(date +"%Y-%m-%dT%H:%M:%S%z")
}

# (number): number
# return callback, set verbose value to enable
_RC() {
    if [ "$verbose" == 1 ]; then
        echo L1, RC, $1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\> >&2
        elif [ "$verbose" == 2 ] || [ "$verbose" == 3 ]  ; then
        echo L$verbose, RC, $1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
    fi;
    return $1
}

# (string): number
# error callback, set verbose value to enable
_ERC() {
    if [ "$verbose" == 1 ]; then
        echo L1, ERC, 1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, "<x "$1" x>" >&2
        elif [ "$verbose" == 2 ] || [ "$verbose" == 3 ]  ; then
        echo L$verbose, ERC, 1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), "<x "$1" x>" >&2
    fi;
    return 1
}

# (string): string
# echo callback
_EC() {
    if [ "$verbose" == 1 ]; then
        echo L1, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\> >&2
        elif [ "$verbose" == 2 ]; then
        echo L2, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
        elif [ "$verbose" == 3 ]; then
        echo L3, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), \"\["$1"\]\" >&2
    fi;
    echo $1
}

# (item1, item2): bool
equal() {
    if [ $1 = $2 ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (path): bool
hasDir() {
    if [ -d "$1" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (path): bool
hasFile() {
    if [ -f "$1" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (cmdName): bool
hasCmd() {
    if [ -x "$(command -v $1)" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (envName): bool
hasEnv() {
    if ! [[ -z ${!1+set} ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (value): bool
hasValue() {
    if ! [[ -z $1 ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (envName, ?replacement): string | null
envGet() {
    if $(hasEnv $1); then _EC "${!1}"; else _EC "$2"; fi;
}

length() {
    if [ ${#1} -gt ${#1[*]} ]; then _EC ${#1}; else _EC ${#1[@]}; fi;
}

# (osTrait): bool
osCheck() {
    case $1 in
        mac | darwin | macos | apple | osx | brew)
            if $(hasCmd uname && uname | grep -q Darwin); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        redhat | dnf | rhel)
            if $(hasCmd dnf); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        centos | yum)
            if $(hasCmd yum); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        alpine | apk)
            if $(hasCmd apk); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        deb | debian | dpkg)
            if $(hasCmd dpkg); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        ubuntu | apt)
            if $(hasCmd apt-get); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        linux)
            if $(echo "$OSTYPE" | grep -q Linux); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        win | windows)
            if $(echo "$OSTYPE" | grep -q msys || echo "$OSTYPE" | grep -q cygwin); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        *)
            if [ "$OSTYPE" == "$1" ]; then return $(_RC 0 $@);
            else return $(_ERC "Error: not listed, this is actual ostype: $OSTYPE");
            fi;
        ;;
    esac
}

# (): string
uuid() {
    local B C='89ab'
    local N=0
    while [ "$N" -lt 16 ]; do
        B=$(( $RANDOM%256 ))
        
        case $N in
            6)
                printf '4%x' $(( B%16 ))
            ;;
            8)
                printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 ))
            ;;
            3 | 5 | 7 | 9)
                printf '%02x-' $B
            ;;
            *)
                printf '%02x' $B
            ;;
        esac
        N=$(( N + 1 ))
    done
    echo
}

# (): string
pkgManager() {
    if $(hasCmd yum); then _EC "yum";
        elif $(hasCmd brew); then _EC "brew";
        elif $(hasCmd apt); then _EC "apt";
        elif $(hasCmd apk); then _EC "apk";
        elif $(hasCmd dnf); then _EC "dnf";
        elif $(hasCmd winget); then _EC "winget";
        elif $(hasCmd choco); then _EC "choco";
    fi;
}

# (...pkgname): string
install() {
    local prefix="" m=$(pkgManager)
    if $(osCheck linux) && $(hasCmd sudo); then prefix=$prefix."sudo "; fi;
    
    if $(stringEqual $m yum); then eval $(_EC "$prefix yum install -y $@");
        elif $(stringEqual $m brew); then eval $(_EC "HOMEBREW_NO_AUTO_UPDATE=1 brew install $@");
        elif $(stringEqual $m apt); then eval $(_EC "$prefix apt-get install -y $@");
        elif $(stringEqual $m apk); then eval $(_EC "$prefix apk add $@");
        elif $(stringEqual $m dnf); then eval $(_EC "$prefix dnf install -y $@");
        elif $(stringEqual $m winget); then eval $(_EC "winget --accept-package-agreements --accept-source-agreements install $@");
        elif $(stringEqual $m choco); then eval $(_EC "choco install -y $@");
    fi;
}

# (defaultValue, userInput): string
varDef() {
    if ! [[ -z $2 ]]; then echo $2; else echo $1; fi;
}

# (length=10, ?useSymbol): string
password() {
    local length=$(varDef 10 $1) symbol=$2 range='A-Za-z0-9'
    if ! [[ -z ${symbol} ]]; then range=$range.'!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'; fi;
    LC_ALL=C tr -dc $range </dev/urandom | head -c $length ; echo
}

# (string): string
## sanitize to cmdline
sanitizeC() {
    local string=$@
    echo "'"${string//\'/\'\\\'\'}"'"
}

# (string, segment): bool
stringContains() {
    if $(echo "$1" | grep -q $2); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (string, search, replace): string
stringReplace() {
    local string=$1 search=$2 replace=$3
    echo "${string//$search/$replace}"
}

# (string, segment): bool
stringEqual() {
    if [ "$1" == "$2" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (name, directory="."): string[]
searchFile() {
    local base=${!2:="."}
    find $base -name $1
}

setup() {
    profile="$HOME/.bashrc"
    storageDir="$HOME/.application/bash_util/"
    
    if $(osCheck mac); then profile="$HOME/.bash_profile"; fi;
    
    if ! $(hasFile "$storageDir/util.sh");  then
        mkdir -p $storageDir
        cp $(_SCRIPTPATH)/util.sh $storageDir
    fi;
    
    if ! $(hasFile "$HOME/.bash_mine"); then
        touch $HOME/.bash_mine
        echo 'source $HOME/.bash_mine' >> $profile
        echo 'function cdd { _back=$(pwd) && cd $1 && ls -a; }' >> $HOME/.bash_mine
        echo 'function cdb { _oldback=$_back && _back=$(pwd) && cd $_oldback && ls -a; }' >> $HOME/.bash_mine
        echo 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16' >> $HOME/.bash_mine
        echo 'export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16' >> $HOME/.bash_mine
        echo "alias u2=$storageDir/util.sh" >> $HOME/.bash_mine
    fi;
    
    cp $(_SCRIPTPATH)/util.sh $storageDir
    source $profile
}

# (): string[]
help(){
    compgen -A function
}

# put this at the end of the file
$@;