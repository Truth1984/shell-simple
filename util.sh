#!/bin/bash
#!/bin/sh

# Author: Awada.Z

# (): string
version() {
    echo 1.2.1
}

storageDir="$HOME/.application/bash_util"

# (): number
# default verbose=3, set verbose=0 to suppress logging
verbose=${verbose:-3}

# (): string
_SCRIPTPATH() {
    echo "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
}

# (): string
_SCRIPTPATHFULL() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
}

_UTILDATE() {
    echo $(date +"%Y-%m-%dT%H:%M:%S%z")
}

_PROFILE() {
    profile="$HOME/.bashrc"
    if $(osCheck mac); then profile="$HOME/.bash_profile"; fi;
    echo $profile
}

# (number): number
# return callback, set verbose value to enable
_RC() {
    if [ "$verbose" = 1 ]; then
        echo L1, RC, $1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\> >&2
    elif [ "$verbose" = 2 ] || [ "$verbose" = 3 ]  ; then
        echo L$verbose, RC, $1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
    fi;
    return $1
}

# (string): number
# error callback, set verbose value to enable
_ERC() {
    if [ "$verbose" = 1 ]; then
        echo L1, ERC, 1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, "<x "$1" x>" >&2
    elif [ "$verbose" = 2 ] || [ "$verbose" = 3 ]  ; then
        echo L$verbose, ERC, 1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), "<x "$1" x>" >&2
    fi;
    return 1
}

# (string): string
# echo callback
_EC() {
    if [ "$verbose" = 1 ]; then
        echo L1, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\> >&2
    elif [ "$verbose" = 2 ]; then
        echo L2, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
    elif [ "$verbose" = 3 ]; then
        echo L3, EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), \"\["$1"\]\" >&2
    fi;
    echo $1
}

# (string): string
# echo debug
_ED() {
    if [ "$verbose" = 1 ]; then
        echo L1, ED, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\> >&2
    elif [ "$verbose" = 2 ]; then
        echo L2, ED, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \""$@"\" >&2
    elif [ "$verbose" = 3 ]; then
        echo L3, ED, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \""$@"\" >&2
    fi;
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
    if ! [[ -z "$(command -v $1)" ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (envName): bool
hasEnv() {
    if ! [[ -z ${!1+set} ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (path, ...content): bool
hasContent() {
    local path=$1 content="${@:2}"
    if ! $(hasFile $path); then return $(_ERC "$path : file not found"); fi;
    if $(cat $1 | grep -q "$content"); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
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

# ():string
ip_local() {
    local ethernet wifi

    if $(osCheck linux); then

        if $(hasCmd ip); then
            ethernet=$(ip addr show eth1 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            wifi=$(ip addr show eth0 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            if $(hasValue $ethernet); then _ED ethernet && _EC $ethernet;
            elif $(hasValue $wifi); then _ED wifi && _EC $wifi; 
            else _ED ip && _EC $(ip route get 1.2.3.4 | awk '{print $7}' | head -1); fi;
        elif $(hasCmd hostname); then
            _ED hostname && _EC $(hostname -i)
        fi;
        
    elif $(osCheck mac);then

        ethernet=$(ipconfig getifaddr en1)
        wifi=$(ipconfig getifaddr en0)
        if $(hasValue $ethernet); then _ED ethernet && _EC $ethernet; 
        else _ED wifi && _EC $wifi; fi;

    fi;
}

# (route_number):string
ip_public() {
    case $1 in
        2) _EC $(get ipinfo.io/ip) ;;
        3) _EC $(get api.ipify.org) ;;
        4) _EC $(get ifconfig.me) ;;
        *) _EC $(get ident.me) ;;
    esac
}

# (osTrait): bool
osCheck() {
    case $1 in
        mac | darwin | macos | apple | osx | brew)
            if $(hasCmd uname && uname | grep -q Darwin); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        centos | yum)
            if $(hasCmd yum); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        alpine | apk)
            if $(hasCmd apk); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        debian | deb | dpkg)
            if $(hasCmd dpkg); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        ubuntu | apt)
            if $(hasCmd apt-get); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        arch | archlinux | pacman )
            if $(hasCmd pacman); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        redhat | dnf | rhel)
            if $(hasCmd dnf); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        linux)
            if $(hasCmd uname) && uname | grep -q Linux; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        win | windows)
            if $(echo "$OSTYPE" | grep -q msys || echo "$OSTYPE" | grep -q cygwin); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
        ;;
        *)
            if [ "$OSTYPE" = "$1" ]; then return $(_RC 0 $@);
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
            6) printf '4%x' $(( B%16 )) ;;
            8) printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 )) ;;
            3 | 5 | 7 | 9) printf '%02x-' $B ;;
            *) printf '%02x' $B ;;
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
    elif $(hasCmd pacman); then _EC "pacman";
    elif $(hasCmd dnf); then _EC "dnf";
    elif $(hasCmd winget); then _EC "winget";
    elif $(hasCmd choco); then _EC "choco";
    fi;
}

# (...?pkgname)
## package update, or general update
upgrade() {
    local prefix="" m=$(pkgManager)
    if $(osCheck linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if $(stringEqual $m yum); then eval $(_EC "$prefix yum update -y $@");
    elif $(stringEqual $m brew); then eval $(_EC "brew install $@");
    elif $(stringEqual $m apt); then eval $(_EC "$prefix apt-get upgrade -y $@");
    elif $(stringEqual $m apk); then eval $(_EC "$prefix apk upgrade $@");
    elif $(stringEqual $m pacman); then eval $(_EC "$prefix pacman -Syu --noconfirm $@");
    elif $(stringEqual $m dnf); then eval $(_EC "$prefix dnf upgrade -y $@");
    elif $(stringEqual $m winget); then eval $(_EC "winget --accept-package-agreements --accept-source-agreements upgrade $@");
    elif $(stringEqual $m choco); then eval $(_EC "choco upgrade -y $@");
    fi;
}

# (...pkgname): string
install() {
    local prefix="" m=$(pkgManager)
    if $(osCheck linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if $(stringEqual $m yum); then eval $(_EC "$prefix yum install -y $@");
    elif $(stringEqual $m brew); then eval $(_EC "HOMEBREW_NO_AUTO_UPDATE=1 brew install $@");
    elif $(stringEqual $m apt); then eval $(_EC "$prefix apt-get install -y $@");
    elif $(stringEqual $m apk); then eval $(_EC "$prefix apk add $@");
    elif $(stringEqual $m pacman); then eval $(_EC "$prefix pacman -Syu --noconfirm $@");
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
    if [ "$1" = "$2" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (name, directory="."): string[]
searchFile() {
    local base=${!2:="."}
    find $base -name $1
}

# (url, data)
post() {
    local url=$1 data=$2
    if $(hasCmd wget); then wget -qO- --header "Content-Type: application/json" --post-data "$data" $url;
        elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url";
    fi;
    echo ""
}

# (url, data)
# post string
posts() {
    local url=$1 data=$2
    if $(hasCmd wget); then wget -qO- --header "Content-Type: text/plain" --post-data "$data" $url;
        elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: text/plain" -d "$data" "$url";
    fi;
    echo ""
}

# (url)
get() {
    local url=$1
    if $(hasCmd wget); then wget -qO- "$url";
        elif $(hasCmd curl); then curl -s -X GET "$url";
    fi;
    echo ""
}

# (url, ?filePath): string
# emit script path
getScript() {
    local url=$1 file
    if $(hasValue $2); then file=$2; else file="/tmp/$(password).sh"; fi;
    download $url $file && chmod 777 $file
    _EC $file
}

# (url, ...param)
getScriptRun() {
    local url=$1
    bash <($(get $url)) ${@:2}
}

# (url, outputFileName?)
download() {
    local url=$1 filename=$2
    if $(hasCmd wget); then
        if $(hasValue $filename); then
            wget -O $filename $url;
        else
            wget $url; 
        fi;
    elif $(hasCmd curl); then
        if $(hasValue $filename); then
            curl $url --output $filename;
        else
            curl -O $url;
        fi;
    fi;
}

# call setup bash beforehand
setup() {
    profile="$(_PROFILE)"

    if ! $(hasFile "$storageDir/util.sh"); then
        mkdir -p $storageDir
        cp $(_SCRIPTPATH)/util.sh $storageDir
    fi;

    if ! $(hasFile "$HOME/.bash_mine"); then
        touch $HOME/.bash_mine
        touch $HOME/.bash_env
        echo 'source $HOME/.bash_mine' >> $profile
        echo 'source $HOME/.bash_env' >> $HOME/.bash_mine
        
        echo 'if [ "$PWD" = "$HOME" ]; then cd Documents; fi;' >> $HOME/.bash_mine
        echo 'PATH=$HOME/.npm_global/bin/:$PATH' >> $HOME/.bash_mine
        echo '' >> $HOME/.bash_mine
        echo 'function cdd { _back=$(pwd) && cd $1 && ls -a; }' >> $HOME/.bash_mine
        echo 'function cdb { _oldback=$_back && _back=$(pwd) && cd $_oldback && ls -a; }' >> $HOME/.bash_mine
        echo 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16' >> $HOME/.bash_mine
        echo 'export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16' >> $HOME/.bash_mine
        echo '' >> $HOME/.bash_mine
        echo 'export https_proxy=$u_proxy' >> $HOME/.bash_mine
        echo 'export http_proxy=$u_proxy' >> $HOME/.bash_mine
        echo 'export HTTPS_PROXY=$u_proxy' >> $HOME/.bash_mine
        echo 'export HTTP_PROXY=$u_proxy' >> $HOME/.bash_mine 
        echo '' >> $HOME/.bash_mine

        if $(osCheck mac); then 
            printf 'export BASH_SILENCE_DEPRECATION_WARNING=1\n' >> $HOME/.bash_mine 
        fi;
    fi;

    source $HOME/.bash_mine
    if ! $(hasContent $HOME/.bash_mine "alias u2"); then
        echo "alias u2=$storageDir/util.sh" >> $HOME/.bash_mine
        ln -s $storageDir/util.sh /usr/local/bin/u2
    fi;

    mv $(_SCRIPTPATH)/util.sh $storageDir
    source $profile
}

update(){
    local scriptLoc="$storageDir/util.sh"
    mkdir -p $storageDir
    local updateUrl="https://raw.githubusercontent.com/Truth1984/shell-simple/main/util.sh"
    local tmpfile=/tmp/$(password).sh
    if $(hasCmd curl); then
        curl $updateUrl --output $tmpfile && mv $tmpfile $scriptLoc
    elif $(hasCmd wget); then
        wget -O $tmpfile $updateUrl && mv $tmpfile $scriptLoc
    fi;

    chmod 777 $scriptLoc
    $scriptLoc setup
}

edit(){
    if $(hasCmd nano); then
        nano $(_SCRIPTPATHFULL)
    elif $(hasCmd vi); then
        vi $(_SCRIPTPATHFULL)
    fi;
}

# (?segment): string[]
help(){    
    if ! [[ -z $1 ]]; then compgen -A function | grep $1; else compgen -A function; fi;
}

# put this at the end of the file
$@;
