#!/usr/bin/env bash

# Author: Awada.Z

# (): string
version() {
    echo 2.2.1
}

storageDirBin="$HOME/.application/bin"
storageDirBinExtra=$storageDirBin/extra

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

# (declare -A Option, ...data): {key:value, _:"" } 
# example: declare -A data; parseArg data $@; parseGet data _;
parseArg() {
    local -n parse_result=$1;
    _target="_"
    for i in ${@:2:$#}; do    
        if ! [[ "$i" =~ ^"-" ]]; then parse_result[$_target]="${parse_result[$_target]}$i ";
        else _target=$(echo $i | sed 's/^-*//'); ! $(hasValueq ${parse_result[$_target]}) && parse_result[$_target]=' ';
        fi;
    done;
}

# (declare -A Option, ...keys): string
parseGet() {
    local -n parse_get=$1;
    for i in ${@:2:$#}; do if ! [[ -z ${parse_get[$i]} ]]; then echo $(_EC "${parse_get[$i]}" $i); fi; done;
    return $(_RC 1 $@);
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

# hasValue quiet
hasValueq() {
    ! [[ -z $1 ]]
}

# (envName, ?replacement): string | null
envGet() {
    if $(hasEnv $1); then _EC "${!1}"; else _EC "$2"; fi;
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

# -p,--public (router_number) Public ip *_default
# -P,--private private ip 
ip() {
    declare -A ip_data; parseArg ip_data $@;
    public=$(parseGet ip_data p public _);
    private=$(parseGet ip_data P private);
    help=$(parseGet ip_data h help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--public,_ \t (router_number) \t display public ip\n'
    helpmsg+='\t-P,--private \t () \t display private ip\n'

    # ():string
    ipLocal() {
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
    ipPublic() {
        case $1 in
            2) _EC $(get ipinfo.io/ip) ;;
            3) _EC $(get api.ipify.org) ;;
            4) _EC $(get ifconfig.me) ;;
            *) _EC $(get ident.me) ;;
        esac
    }

    if $(hasValueq $help); then printf "$helpmsg"; 
    elif $(hasValueq $public); then ipPublic $public; 
    elif $(hasValueq $private); then ipLocal $private; 
    else ipPublic $public; 
    fi;
}

# (): string
pkgManager() {
    if $(hasCmd yum); then _EC "yum";
    elif $(hasCmd brew); then _EC "brew";
    elif $(hasCmd apt); then _EC "apt";
    elif $(hasCmd apk); then _EC "apk";
    elif $(hasCmd pacman); then _EC "pacman";
    elif $(hasCmd dnf); then _EC "dnf";
    elif $(hasCmd choco); then _EC "choco";
    elif $(hasCmd winget); then _EC "winget";
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
    elif $(stringEqual $m choco); then eval $(_EC "choco upgrade -y $@");
    elif $(stringEqual $m winget); then eval $(_EC "winget upgrade --accept-package-agreements --accept-source-agreements $@");
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
    elif $(stringEqual $m choco); then eval $(_EC "choco install -y $@");
    elif $(stringEqual $m winget); then eval $(_EC "winget install --accept-package-agreements --accept-source-agreements $@");
    fi;
}

# (length=10, ?useSymbol): string
password() {
    local length=${1:-10} symbol=$2 range='A-Za-z0-9'
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

noproxy() {
    https_proxy="" http_proxy="" HTTPS_PROXY="" HTTP_PROXY="" no_proxy="" NO_PROXY="" $@
}

# (name, directory="."): string[]
searchFile() {
    local base=${!2:="."}
    find $base -name $1
}

# -u,--url,_ *_default
# -j,--json, *_2
# -s,--string post string
post() {
    declare -A post_data; parseArg post_data $@;
    url=$(parseGet post_data u url _);
    json=$(parseGet post_data j json);
    string=$(parseGet post_data s string);
    help=$(parseGet post_data help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-j,--json \t (string) \t json data to post\n'
    helpmsg+='\t-s,--string \t (string) \t string data to post\n'

    # (url, data)
    post_json(){
        local url=$1 data=$2
        if $(hasCmd wget); then wget -qO- --header "Content-Type: application/json" --post-data "$data" $url;
            elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url";
        fi;
        echo "" 
    }

    # (url, data)
    post_string() {
        local url=$1 data=$2
        if $(hasCmd wget); then wget -qO- --header "Content-Type: text/plain" --post-data "$data" $url;
            elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: text/plain" -d "$data" "$url";
        fi;
        echo ""
    }
    
    if $(hasValueq $help); then printf "$helpmsg"; 
    elif $(hasValueq $string); then post_string $url $string;
    elif $(hasValueq $json); then post_json $url $json; 
    else post_json $url; 
    fi;
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
        if $(hasValue $filename); then wget -O $filename $url; else wget $url; fi;
    elif $(hasCmd curl); then
        if $(hasValue $filename); then curl $url --output $filename; else curl -O $url; fi;
    fi;
}

# call setup bash beforehand
setup() {
    profile="$(_PROFILE)"
    mkdir -p $storageDirBin && mkdir -p $storageDirBinExtra

    if ! $(hasFile "$HOME/.bash_mine"); then
        touch $HOME/.bash_mine && touch $HOME/.bash_env
        echo 'source $HOME/.bash_mine' >> $profile
        echo 'source $HOME/.bash_env' >> $HOME/.bash_mine
        
        echo 'if [ "$PWD" = "$HOME" ]; then cd Documents; fi;' >> $HOME/.bash_mine
        echo 'PATH=$HOME/.npm_global/bin:'$storageDirBin':$PATH' >> $HOME/.bash_mine
        echo 'function cdd { _back=$(pwd) && cd $@ && ls -a; }' >> $HOME/.bash_mine
        echo 'function cdb { _oldback=$_back && _back=$(pwd) && cd $_oldback && ls -a; }' >> $HOME/.bash_mine

        printf 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\nexport NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\n\n' >> $HOME/.bash_mine 
        printf 'export https_proxy=$u_proxy\nexport http_proxy=$u_proxy\nexport HTTPS_PROXY=$u_proxy\nexport HTTP_PROXY=$u_proxy\n\n' >> $HOME/.bash_mine

        if $(osCheck mac); then printf 'export BASH_SILENCE_DEPRECATION_WARNING=1\n' >> $HOME/.bash_mine; fi;
    fi;

    mv $(_SCRIPTPATHFULL) $storageDirBin/u2
}

update(){
    local scriptLoc="$storageDirBin/u2"
    local updateUrl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"
    local tmpfile=/tmp/$(password).sh
    if $(hasCmd curl); then curl $updateUrl --output $tmpfile
    elif $(hasCmd wget); then wget -O $tmpfile $updateUrl
    fi;

    chmod 777 $tmpfile && $tmpfile setup
}

edit(){
    if $(hasCmd nano); then nano $(_SCRIPTPATHFULL);
    elif $(hasCmd vi); then vi $(_SCRIPTPATHFULL); fi;
}

# (?segment): string[]
help(){    
    if ! [[ -z $1 ]]; then compgen -A function | grep $1; else compgen -A function; fi;
}

if [ -d $storageDirBinExtra ]; then for i in $(ls $storageDirBinExtra); do source $storageDirBinExtra/$i; done; fi;

# put this at the end of the file
$@;
