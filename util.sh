#!/usr/bin/env bash

# Author: Awada.Z

# (): string
version() {
    echo 8.6.2
}

_U2_Storage_Dir="$HOME/.application"
_U2_Storage_Dir_Quick="$_U2_Storage_Dir/quick"
_U2_Storage_Dir_Bin="$_U2_Storage_Dir/bin"
_U2_Storage_Dir_Trash="$_U2_Storage_Dir/.trash"

# (): number
# default verbose=1, set verbose to something else to suppress logging
if [ -z "$verbose" ] || [ "$verbose" = "true" ] || [ "$verbose" = "1" ]; then verbose="1"; 
else verbose=""; fi;

# (): string
_SCRIPTPATH() {
    echo "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
}

# eval following line to get the current dir
_PATH() {
    echo 'echo "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"'
}

__dirname() {
    exec echo "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
}

# (): string
_SCRIPTPATHFULL() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
}

# eval following line to get the current path
_PATHFULL() {
    echo 'echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"'
}

_UTILDATE() {
    echo $(date +"%Y-%m-%dT%H:%M:%S%z")
}

_PROFILE() {
    local profile="$HOME/.bashrc"
    if $(os -c mac); then profile="$HOME/.bash_profile"; fi;
    echo $profile
}

# (number): number
# return callback, set verbose value to enable
_RC() {
    if [ -n "$verbose" ]; then
        echo RC, $1, $(basename "$0"), $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
    fi;
    return $1
}

# (string): number
# error callback, set verbose value to enable
_ERC() {
    if [ -n "$verbose" ]; then
        echo ERC, 1, $(basename "$0"), $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), "<x "$1" x>" >&2
    fi;
    return 1
}

# (string): string
# echo callback
_EC() {
    if [ -n "$verbose" ]; then
        echo EC, 0, $(basename "$0"), $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), \"\["$1"\]\" >&2
    fi;
    echo "$@"
}

# (string): string
# echo debug
_ED() {
    if [ -n "$verbose" ]; then
        echo ED, 0, $(basename "$0"), $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \""$@"\" >&2
    fi;
}

# echo array
_EA() {
    _ED printing array {$1}
    local -n print_data=$1;
    for i in "${!print_data[@]}"; do printf '[%s]: %s\n' "$i" "${print_data[$i]}"; done; 
}

# echo to file descriptor 2
_E2() {
    $@ >&2
}

# Quiet, get rid of descriptor 2
_EQ() {
    $@ 2> /dev/null
}

# Quiet, no output 
_ENULL() {
    $@ > /dev/null 2>&1
}

# (declare -A Option, ...data): {key:value, _:"" } 
# example: declare -A data; parseArg data $@; parseGet data _;
parseArg() {
    local -n parse_result=$1;
    local _target="_";

    for i in ${@:2:$#}; do    
        if ! [[ "$i" =~ ^"-" ]]; then parse_result[$_target]="${parse_result[$_target]}$i ";
        else _target=$(echo " $i" | sed 's/^ -*//'); [[ -z "${parse_result[$_target]}" ]] && parse_result[$_target]=' '; 
        fi; 
    done;

    if [[ -p /dev/stdin ]]; then
        while IFS= read -r line; do
            parse_result[$_target]=$line
        done < /dev/stdin
    fi; 
}

# only parse first arguments
# -h a b c -h ddd -> -h:a b c
parseArg1() {
    local -n parse_result=$1;
    local _target="_";
    local intake="true"; 

    for i in "${@:2}"; do
        if [[ "$i" =~ ^"-" ]]; then
            _target=$(echo "$i" | sed 's/^\s*-*//')
            if [[ -z "${parse_result[$_target]}" ]]; then
                parse_result[$_target]=' '
                intake="true"
            else
                intake="false"
            fi
        else
            if [[ "$intake" == "true" ]]; then
                parse_result[$_target]="${parse_result[$_target]}$i "
            fi
        fi
    done
}

# (declare -A Option, ...keys): string
parseGet() {
    local -n parse_get=$1;
    for i in ${@:2:$#}; do if ! [[ -z ${parse_get[$i]} ]]; then _EC "${parse_get[$i]}" && return $(_RC 0 $@); fi; done;
    return 1;
}

parseGetQ() {
    local -n parse_get=$1;
    for i in ${@:2:$#}; do if ! [[ -z ${parse_get[$i]} ]]; then echo "${parse_get[$i]}"; fi; done;
    return 1;
}

pathGetFull() {
    local path=$(cd "$(dirname "$@")" || exit; pwd)
    local file=$(basename "$@")

    if [ "$file" = ".." ]; then
        _EC "$(dirname "$path")"
    else
        _EC "$path/$file"
    fi
}

trimArgs() {
    local joined=""
    for str in "$@"; do
        joined="$joined$(echo "$str" | xargs)"
    done
    _EC "$joined"
}

# takes in question, and return 1 as yes, 2 as no, default as 0
# Return int if entered int
prompt() {
    local prompter="$@"
    read -p "$prompter"$'\n' response

    if [[ "$response" =~ [0-9]+ ]]; then
        echo $response
    else
        case "$response" in
            [yY]|[yY][eE][sS])
                echo 1
            ;;
            [nN]|[nN][oO])
                echo 2
            ;;
            *)
                echo 0 ;
            ;;
        esac
    fi;
}

# unable to receive reference from outside of the script, unless source first
# (PromptString, arrayName) 
_promptArray() {
    local prompter=$1 
    local -n options=$2

    if ! $(hasValueq ${@:2}); then return $(_ERC "selection collection empty"); fi; 

    for ((i = 0; i < ${#options[@]}; i++)); do
        prompter+=$'\n'"[$i]: ${options[i]}"
    done
    prompter+=$'\n'"Your Option? Default [0] as ${options[0]}:"
    read -p "$prompter"$'\n' responseIndex

    if ! $(hasValueq $responseIndex); then 
        _ED return index [0] as ${options[0]}
        echo ${options[0]}
    elif ! [[ "$responseIndex" =~ [0-9]+ ]]; then
        return $(_ERC "response index not a number"); 
    else
        _ED return index [$responseIndex] : ${options[$responseIndex]}
        echo ${options[$responseIndex]}
    fi;
}

# just read input
promptString() {
    local prompter="$@"
    read -p "$prompter"$'\n' responseString
    echo "$responseString"
}

promptSecret() {
    local prompter="$@"
    read -s -p "$prompter"$'\n' responseString
    echo "$responseString"
}

# $1:question $2...:select options; i.e. Choose? i1 i2 i3
promptSelect() {
    local prompter=$1 options=("${@:2}")

    if ! $(hasValueq ${@:2}); then return $(_ERC "selection collection empty"); fi; 

    for ((i = 0; i < ${#options[@]}; i++)); do
        prompter+=$'\n'"[$i]: ${options[i]}"
    done
    prompter+=$'\n'"Your Option? Default [0] as ${options[0]}:"
    read -p "$prompter"$'\n' responseIndex

    if ! $(hasValueq $responseIndex); then 
        _ED return index [0] as ${options[0]}
        echo ${options[0]}
    elif ! [[ "$responseIndex" =~ [0-9]+ ]]; then
        return $(_ERC "response index not a number"); 
    else
        _ED return index [$responseIndex] : ${options[$responseIndex]}
        echo ${options[$responseIndex]}
    fi;
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
    env -i HOME="$HOME" PATH="$PATH" "$(command -v bash)" -c "command -v '$1'" >/dev/null 2>&1 && return $(_RC 0 $@) || return $(_RC 1 $@);
}


# (cmdName): bool
hasCmdq() {
   env -i HOME="$HOME" PATH="$PATH" "$(command -v bash)" -c "command -v '$1'" >/dev/null 2>&1 && return 0 || return 1;
}

# (envName): bool
hasEnv() {
    if ! [[ -z ${!1+set} ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (path, ...content): bool
hasContent() {
    local path=$1 content="${@:2}"
    if ! $(hasFile $path); then return $(_ERC "$path : file not found"); fi;
    if $(cat $1 | grep -q "$content"); then return $(_RC 0 "$@"); else return $(_RC 1 "$@"); fi;
}

# (value): bool
hasValue() {
    if ! [[ -z $1 ]]; then return $(_RC 0 "$@"); else return $(_RC 1 "$@"); fi;
}

# hasValue quiet
hasValueq() {
    ! [[ -z $1 ]]
}

has() { 
    declare -A has_data; parseArg has_data $@;

    if [ "$_target" = "_" ]; then 
        return $(! [[ -z $1 ]]); 
    fi;

    local cmd=$(parseGet has_data c cmd command);
    local cmdQ=$(parseGetQ has_data C Cmd Command);
    local dir=$(parseGet has_data d dir);
    local dirQ=$(parseGetQ has_data D Dir);
    local file=$(parseGet has_data f file);
    local fileQ=$(parseGetQ has_data F File);
    local path=$(parseGet has_data p path);
    local pathQ=$(parseGetQ has_data P Path);
    local env=$(parseGet has_data e env);
    local envQ=$(parseGetQ has_data E Env);
    local help=$(parseGet has_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--cmd \t (string) \t check if it has command\n'
    helpmsg+='\t-C,--Cmd \t (string) \t check if it has command quietly\n'
    helpmsg+='\t-d,--dir \t (string) \t check if it has directory\n'
    helpmsg+='\t-D,--Dir \t (string) \t check if it has directory quietly\n'
    helpmsg+='\t-f,--file \t (string) \t check if it has file\n'
    helpmsg+='\t-F,--File \t (string) \t check if it has file quietly\n'
    helpmsg+='\t-p,--path \t (string) \t check if it has path, both dir or file\n'
    helpmsg+='\t-P,--Path \t (string) \t check if it has path quietly, both dir or file\n'
    helpmsg+='\t-e,--env \t (string) \t check if it has environment\n'
    helpmsg+='\t-E,--Env \t (string) \t check if it has environment quietly\n'

    cmd_has() {
        if ! [[ -z "$(command -v $1)" ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    cmd_Q_has() {
        ! [[ -z "$(command -v "$1")" ]];
    }

    dir_has() {
        local lpath="$@"
        if [ -d "$lpath" ]; then return $(_RC 0 $lpath); else return $(_RC 1 $lpath); fi;
    }

    dir_Q_has() {
        local lpath="$@"
        [ -d "$lpath" ];
    }

    file_has() {
        local lpath="$@"
        if [ -f "$lpath" ]; then return $(_RC 0 $lpath); else return $(_RC 1 $lpath); fi;
    }

    file_Q_has() {
        local lpath="$@"
        [ -f "$lpath" ];
    }

    path_has() {
        local lpath="$@"
        if [ -e "$lpath" ]; then return $(_RC 0 $lpath); else return $(_RC 1 $lpath); fi;
    }

    path_Q_has() {
        local lpath="$@"
        [ -e "$lpath" ];
    }

    env_has() {
        if ! [[ -z ${!1+set} ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    env_Q_has() {
        ! [[ -z ${!1+set} ]]; 
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$cmd"); then cmd_has $cmd; 
    elif $(hasValueq "$cmdQ"); then cmd_Q_has $cmdQ; 
    elif $(hasValueq "$dir"); then dir_has $dir; 
    elif $(hasValueq "$dirQ"); then dir_Q_has $dirQ; 
    elif $(hasValueq "$file"); then file_has $file; 
    elif $(hasValueq "$fileQ"); then file_Q_has $fileQ; 
    elif $(hasValueq "$path"); then path_has $path; 
    elif $(hasValueq "$pathQ"); then path_Q_has $pathQ; 
    elif $(hasValueq "$env"); then env_has $env; 
    elif $(hasValueq "$envQ"); then env_Q_has $envQ; 
    fi;

}

# (envName, ?replacement): string | null
envGet() {
    if $(hasEnv $1); then _EC "${!1}"; else _EC "$2"; fi;
}

# -s,--size,_ *_default
# -m,--modify modify date
# -M,--modifyQ modify date quiet output long
# -f,--full full info
stat() {
    declare -A stats_data; parseArg stats_data $@;
    local size=$(parseGet stats_data s size _);
    local modify=$(parseGet stats_data m modify);
    local modifyQ=$(parseGet stats_data M modifyQ);
    local full=$(parseGet stats_data f full);
    local help=$(parseGet stats_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-s,--size,_ \t (string) \t size of the path\n'
    helpmsg+='\t-m,--modify \t (string) \t modify date of the path\n'
    helpmsg+='\t-M,--modifyQ \t (string) \t modify date of the path as long, quiet\n'
    helpmsg+='\t-f,--full \t (string) \t full stats info\n'

    unset -f stat;
    STAT=$(which stat);

    size_stats() {
        _EC $(du -sh $1 | cut -f1)
    }

    modify_stats() {
        if $(os -c mac); then _EC $($STAT -f "%Sm" -t "%Y-%m-%d %H:%M:%S" $1); 
        else _EC $($STAT --printf="%y\n" $1 | awk -F'[ .]' '{print $1, $2}'); fi;
    }

    modifyQ_stats() {
         # os -c mac quiet
        if $(hasCmdq uname && uname | grep -q Darwin); then
            $STAT -f "%Sm" -t "%s" $1
        else
            formatDate=$($STAT --printf="%y\n" "$1" | awk -F'[ .]' '{print $1, $2}')
            date -d "$formatDate" +%s
        fi;
    }

    full_stats() {
        size_stats $1
        modify_stats $1
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$size"); then size_stats $size; 
    elif $(hasValueq "$modify"); then modify_stats $modify; 
    elif $(hasValueq "$modifyQ"); then modifyQ_stats $modifyQ; 
    elif $(hasValueq "$full"); then full_stats $full; 
    fi;
}

# -c,--check,_ *_default
# -p,--pkgmanager
# -i,--info
# -s,--sys
os() {
    declare -A os_data; parseArg os_data $@;
    local check=$(parseGet os_data c check _);
    local pkgmanager=$(parseGet os_data p pkgmanager);
    local info=$(parseGet os_data i info);
    local sysinfo=$(parseGet os_data s sys);
    local bashinfo=$(parseGet os_data b bash);
    local help=$(parseGet os_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--check,_ \t\t (string) \t check os trait fit current os\n'
    helpmsg+='\t-p,--pkgmanager \t () \t\t get current package manager\n'
    helpmsg+='\t-i,--info \t\t () \t\t get os info, including hardware\n'
    helpmsg+='\t-s,--sys \t\t () \t\t get system info, with cpu, mem and disk info\n'
    helpmsg+='\t-b,--bash \t\t () \t\t get bash info, with active one and installed one\n'

    # (): string
    pkgManager_os() {
        if $(hasCmd yum); then _EC "yum";
        elif $(hasCmd brew); then _EC "brew";
        elif $(hasCmd apt); then _EC "apt";
        elif $(hasCmd apk); then _EC "apk";
        elif $(hasCmd pacman); then _EC "pacman";
        elif $(hasCmd dnf); then _EC "dnf";
        elif $(hasCmd choco); then _EC "choco";
        elif $(hasCmd winget); then _EC "winget";
        else _EC "NONE"; 
        fi;
    }

    # (osTrait): bool
    check_os() {
        case $1 in
            mac | darwin | macos | apple | osx | brew)
                if $(hasCmdq uname && uname | grep -q Darwin); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            centos | yum)
                if $(hasCmdq yum); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            alpine | apk)
                if $(hasCmdq apk); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            debian | deb | dpkg)
                if $(hasCmdq dpkg); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            ubuntu | apt)
                if $(hasCmdq apt-get); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            arch | archlinux | pacman )
                if $(hasCmdq pacman); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            redhat | dnf | rhel)
                if $(hasCmdq dnf); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
            ;;
            linux)
                if $(hasCmdq uname) && uname | grep -q Linux; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
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

    info_os() {
        echo Package Manager: $(pkgManager_os);
        if $(hasCmdq uname); then uname -a; fi;
        if [ -f "/etc/os-release" ]; then cat /etc/os-release; fi;
        if $(hasCmdq wmic); then wmic os get Caption, Version, BuildNumber; fi;

        # hardware, CPU, GPU, MEM, DISK
        if $(hasCmdq systeminfo); then systeminfo; return; fi;
        if $(hasCmdq system_profiler); then system_profiler SPSoftwareDataType SPHardwareDataType SPDisplaysDataType SPSerialATADataType; return; fi;
        if $(hasCmdq lshw); then lshw -short | cat; fi;
    }

    sys_os() {
        if $(os -c mac); then 
            df -hP;
            top -l 1 | head -n 10
        elif $(os -c linux); then 
            df -Th --exclude-type=overlay;
            top -bn1 | head -n 6
        elif $(os -c win); then 
            wmic logicaldisk get name,size,freespace
            wmic cpu get LoadPercentage
            wmic memorychip get Capacity,Speed,Manufacturer,ConfiguredClockSpeed
        fi;
    }

    bash_os() {
        echo -e Session bash: "\t" $(echo $BASH_VERSION);
        echo -e System bash: "\t" $(bash --version | head -n 1); 
        _ED use 'ln $(which bash) /bin/bash' to use the new bash
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$check"); then check_os $check; 
    elif $(hasValueq "$pkgmanager"); then pkgManager_os $pkgmanager; 
    elif $(hasValueq "$sysinfo"); then sys_os $sysinfo;
    elif $(hasValueq "$bashinfo"); then bash_os $bashinfo;
    elif $(hasValueq "$info"); then info_os $info; 
    fi;

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

# -p,--public (route_number) Public ip *_default
# -4,--ipv4 () bool, use ipv4 to connect to internet *_default
# -6,--ipv6 () bool, use ipv6 to connect to internet
# -P,--private () private ip 
ip() {
    declare -A ip_data; parseArg ip_data $@;
    local public=$(parseGet ip_data p public _);
    local private=$(parseGet ip_data P private);
    local ipv4=$(parseGet ip_data 4 ipv4);
    local ipv6=$(parseGet ip_data 6 ipv6);
    local help=$(parseGet ip_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--public,_ \t (4/6) \t ipv4 / ipv6, display public ip\n'
    helpmsg+='\t-4,--ipv4 \t () \t use ipv4 to connect to internet\n'
    helpmsg+='\t-6,--ipv6 \t () \t use ipv6 to connect to internet\n'
    helpmsg+='\t-P,--private \t () \t display private ip\n'

    # ():string
    ipLocal() {
        local ethernet wifi

        if $(os -c linux); then
            unset -f ip;
            IP=$(which ip);
            ethernet=$($IP addr show eth1 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            wifi=$($IP addr show eth0 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            if $(hasValue $ethernet); then _ED ethernet && _EC $ethernet;
            elif $(hasValue $wifi); then _ED wifi && _EC $wifi; 
            else _ED ip && _EC $($IP route get 1.2.3.4 | awk '{print $7}' | head -1); fi;
        elif $(os -c mac);then
            ethernet=$(ipconfig getifaddr en1)
            wifi=$(ipconfig getifaddr en0)
            if $(hasValue $ethernet); then _ED ethernet && _EC $ethernet; 
            else _ED wifi && _EC $wifi; fi;
        fi;
    }

    get2() {
        local url=$1 version=$2 wgetArg="--inet4-only --prefer-family=IPv4" curlArg="--ipv4"
        if $(string -e "$version" 6); then wgetArg="--inet6-only --prefer-family=IPv6" curlArg="--ipv6"; fi;
        if $(hasCmd wget); then wget -qO- $wgetArg "$url";
            elif $(hasCmd curl); then curl -s -X $curlArg GET "$url";
        fi; 
        echo ""
    }

    # (route_number):string
    ipPublic() {
        iv=4
        if $(hasValueq "$ipv6"); then iv=6; fi;
        case $1 in
            2) _ED ipinfo.io/ip with ipv$iv && _EC $(get2 ipinfo.io/ip $iv) ;;
            3) _ED api.ipify.org with ipv$iv && _EC $(get2 api.ipify.org $iv) ;;
            4) _ED ifconfig.me with ipv$iv && _EC $(get2 ifconfig.me $iv) ;;
            *) _ED ident.me with ipv$iv && _EC $(get2 ident.me $iv) ;;
        esac
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$public"); then ipPublic $public; 
    elif $(hasValueq "$private"); then ipLocal $private; 
    else ipPublic $public; 
    fi;
}

dates() {
    declare -A date_data; parseArg date_data $@;
    local parse=$(parseGet date_data p parse _);
    local parseQ=$(parseGetQ date_data p parse _ q quiet);
    local dateTime=$(parseGet date_data D Datetime);
    local dateLong=$(parseGet date_data l long);
    local dateOnly=$(parseGet date_data d date);
    local timeOnly=$(parseGet date_data t time);
    local plain=$(parseGet date_data P plain);
    local iso=$(parseGet date_data i iso);
    local full=$(parseGet date_data f full)
    local older=$(parseGet date_data o older)
    local help=$(parseGet date_data help);

    local dateFormat='%Y-%m-%d'
    local timeFormat='%H:%M:%S'
    local dateTimeFormat='%Y-%m-%d %H:%M:%S'
    local dateLongFormat='%s'
    local plainFormat='%Y_%m_%d_%H_%M_%S'
    local iso8601="%Y-%m-%dT%H:%M:%S%z"

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--parse,_ \t\t () \t\t parse date from string, can use "now"\n'
    helpmsg+='\t-q,--quiet \t\t () \t\t parse date quiet from string, can use "now"\n'
    helpmsg+='\t-D,--Datetime, \t\t () \t\t date as datetime format\n'
    helpmsg+='\t-l,--long \t\t () \t\t date as long format\n'
    helpmsg+='\t-d,--date \t\t () \t\t date only format of date\n'
    helpmsg+='\t-t,--time \t\t () \t\t time only format of date\n'
    helpmsg+='\t-P,--plain \t\t () \t\t plain format of date\n'
    helpmsg+='\t-f,--full \t\t () \t\t full display format of date\n'
    helpmsg+='\t-o,--older \t\t (time1, time2?, gap?) \t time2 can be "now", if gap exist, use absolute num for diff\n'

    if $(hasCmdq gdate); then DATE=$(which gdate);
    else DATE=$(which date); fi;

    parse_dates() {
        local input=$(echo $@ | xargs)
        plainFormat="[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+"
        longFormat="^[0-9]+$"
        now="now"
        
        if [[ $input =~ $plainFormat ]]; then input=$(echo "$input" | awk -F_ '{printf("%s-%s-%s %s:%s:%s", $1, $2, $3, $4, $5, $6)}'); 
        elif [[ $input =~ $longFormat ]]; then echo $input;
        elif [[ $input =~ $now ]]; then date +%s;
        else $DATE -d "$input" +%s; 
        fi;
    }

    if ! $(hasValueq $parseQ); then time=$(date +%s);
    else time=$(parse_dates $parseQ); fi; 
    if ! $(hasValueq $time); then return $(_ERC "time parsing error, time missing"); fi;

    toFormat_dates() {
        echo $($DATE -d "@$time" +"$1")
    }

    older_dates() {
        shift
        value1="$1"
        value2="$2"
        gap="$3"

        _ED value1 {$value1} value2 {$value2} gap {$gap}
        if ! $(hasValueq $value2); then 
            return $(_ERC "value 1 missing")
        fi;

        if ! $(hasValueq $value2); then 
            _ED "value2 missing, using current time"; 
            value2=$time
        fi;

        value1=$(parse_dates $value1);
        value2=$(parse_dates $value2);
        difference=$(($value1 - $value2));

        if $(hasValueq $gap); then 
            _ED gap {$gap} found, using absolute number
            difference=${difference#-}
            if [ "$difference" -gt $gap ]; then _RC 0 difference:$difference '>' $gap;
            else _RC 1 difference:$difference '<=' $gap; 
            fi;
        elif [ "$difference" -gt 0 ]; then _RC 0 difference:$value1 '>' $value2;
        else _RC 1 difference:$value1 '<=' $value2; fi;
    }

    full_dates() {
        _ED "-D,Datetime" "$dateTimeFormat" 
        toFormat_dates "$dateTimeFormat"; 
        _ED "-l,long" "$dateLongFormat" 
        toFormat_dates "$dateLongFormat"; 
        _ED "-d,date" "$dateFormat"
        toFormat_dates "$dateFormat"; 
        _ED "-t,time" "$timeFormat"
        toFormat_dates "$timeFormat"; 
        _ED "-p,plain" "$plainFormat"
        toFormat_dates "$plainFormat"; 
        _ED "-i,iso" "$iso8601"
        toFormat_dates "$iso8601";
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$dateTime"); then toFormat_dates "$dateTimeFormat"; 
    elif $(hasValueq "$dateLong"); then toFormat_dates "$dateLongFormat"; 
    elif $(hasValueq "$dateOnly"); then toFormat_dates "$dateFormat"; 
    elif $(hasValueq "$timeOnly"); then toFormat_dates "$timeFormat"; 
    elif $(hasValueq "$plain"); then toFormat_dates "$plainFormat"; 
    elif $(hasValueq "$iso"); then toFormat_dates "$iso8601"; 
    elif $(hasValueq "$older"); then older_dates "$@"; 
    elif $(hasValueq "$full"); then full_dates $full; 
    else toFormat_dates "$dateTimeFormat"; 
    fi;
}

# -p,--path path to trash, *_default
# -l,--list list trash 
# -i,--index get path from index
# -r,--restore restore file
# -c,--clean clean trash older than 3 month
# -d,--delete delete one
# -P,--purge rm all files from trash dir
trash() {
    declare -A trash_data; parseArg trash_data $@;
    declare -A folder_data;
    local path=$(parseGet trash_data p path _);
    local list=$(parseGet trash_data l list);
    local indexDir=$(parseGet trash_data i index);
    local restore=$(parseGet trash_data r restore);
    local restoreIndex=$(parseGet trash_data R restoreindex);
    local clean=$(parseGet trash_data c clean);
    local delete=$(parseGet trash_data d delete);
    local purge=$(parseGet trash_data P purge);
    local help=$(parseGet trash_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--path,_ \t (string) \t move target path to trash path\n'
    helpmsg+='\t-l,--list \t (string) \t list infos on current input path, default to list all\n'
    helpmsg+='\t-i,--index \t (number) \t input index number and get target trash dir\n'
    helpmsg+='\t-r,--restore \t (string) \t restore folder depends on current path\n'
    helpmsg+='\t-R,--restoreindex \t (string) \t restore folder depends on index\n'
    helpmsg+='\t-c,--clean \t (number) \t clean trash older than 3 month, default 7890000 \n'
    helpmsg+='\t-d,--delete \t () \t choose a trash and delete it \n'
    helpmsg+='\t-P,--purge \t () \t\t remove all trash from trash path\n'

    local TP="$_U2_Storage_Dir_Trash"
    local trashInfoName="_U2_TRASH_INFO"

    put_trash() {
        local input="$@"
        if ! $(hasValueq $input); then return $(_ERC "to trash path not specified"); fi; 

        for file in $input; do
            inputPath=$(pathGetFull "$file")
            if ! $(has --Path "$inputPath"); then return $(_ERC "input path {$inputPath} not exist"); fi;
            local uid="$(uuid)"
            local trashDir=$(trimArgs $TP / $uid)
            local size=$(du -sh "$inputPath" | awk '{print $1}')
            local infoDir=$(trimArgs $trashDir / $trashInfoName)
            mkdir -p $trashDir
            mv -fv "$inputPath" $trashDir
            printf "uuid=$uid \noriginalDir=$inputPath \ndtime=$(date +'%Y-%m-%d %H:%M:%S')\nsize=$size\n" > $infoDir
        done
    }

    loadArray() {
        readarray -t folders < <(ls -lt "$TP" | tail -n +2 | awk '{print $9}')
        folder_data[length]=${#folders[@]}
        
        for ((i=0; i<${#folders[@]}; i++)); do
            folder=${folders[i]}
            info_file=$(trimArgs $TP / $folder / $trashInfoName)
            while IFS= read -r line; do
                folder_data["${i}_index"]=$i
            if [[ $line == "uuid="* ]]; then
                folder_data[${i}_uuid]=${line#"uuid="}
            elif [[ $line == "originalDir="* ]]; then
                folder_data[${i}_original_dir]=${line#"originalDir="}
            elif [[ $line == "dtime="* ]]; then
                folder_data[${i}_dtime]=${line#"dtime="}
            elif [[ $line == "size="* ]]; then
                folder_data[${i}_size]=${line#"size="}
            fi
            done < "$info_file"
        done
    }

    # call loadArray() beforehand, $1:index, $2: eval condition
    trashFilter() {
        local indexStr=$1
        local evalStr=$2
        
        local length=${folder_data[length]}
        for ((i=0; i<$length; i++)); do     
            target=${folder_data[${i}_${indexStr}]}
            if ! $(eval "$evalStr \"$target\""); then
                unset folder_data[${i}_index]
                unset folder_data[${i}_uuid]
                unset folder_data[${i}_original_dir]
                unset folder_data[${i}_dtime]
                unset folder_data[${i}_size]
            fi;
        done
    }

    # $1 eval if condition
    printTrashList(){
        printf 'index:\tOriginal Directory:\t\t\t\t\tDeletetime:\t\tSize:\tDIR:\n'
        local length=${folder_data[length]}

        for ((i=0; i<$length; i++)); do  
            uuid=${folder_data[${i}_uuid]}   
            if ! $(hasValueq $uuid); then continue; fi;
            index=${folder_data[${i}_index]}
            original_dir=${folder_data[${i}_original_dir]}
            dtime=${folder_data[${i}_dtime]}
            size=${folder_data[${i}_size]}
            printf  "$index\t$original_dir\t\t$dtime\t$size\t$(echo $TP/$uuid | xargs)\n"
        done
    }

    list_trash() {
        local dir=$1
        loadArray   
        
        if ! $(hasValueq $dir); then
            printTrashList
        else
            dir=$(pathGetFull $dir)
            trashFilter "original_dir" 'a(){ if $(echo $1 | grep -q'" $dir); then return 0; else return 1; fi; }; a"
            printTrashList 
        fi;
    }

    restore_trash() {
        local dir=$1
        if ! $(hasValueq $dir); then dir="."; fi;
        loadArray   

        dir=$(pathGetFull $dir)

        trashFilter "original_dir" 'a(){ if $(echo $1 | grep -q'" $dir); then return 0; else return 1; fi; }; a"
        printTrashList 

        if [ ${#folder_data[@]} -lt 2 ]; then
            return $(_ERC "Error: empty, nothing to restore in $dir");
        fi;

        response=$(prompt "which one to restore ? [index:0]")

        if ! $(hasValueq ${folder_data[${response}_uuid]}); then return $(_ERC "index:$response does not exit"); fi;
        uuid=${folder_data[${response}_uuid]}
        original_dir=${folder_data[${response}_original_dir]}

        targetTrashDir=$(trimArgs $TP / $uuid) 
        mv $(trimArgs $targetTrashDir / $trashInfoName) /tmp
        mv -i $(trimArgs $targetTrashDir "/*") "$(dirname "$original_dir")"
    }

    restoreIndex_trash() {
        local indexTrash=$1
        loadArray   

        if $(hasValueq $indexTrash); then response=$indexTrash;
        else printTrashList && response=$(prompt "which one to restore ? [index:0]"); fi;

        if ! $(hasValueq ${folder_data[${response}_uuid]}); then return $(_ERC "index:$response does not exit"); fi;
        uuid=${folder_data[${response}_uuid]}
        original_dir=${folder_data[${response}_original_dir]}

        targetTrashDir=$(trimArgs $TP / $uuid) 
        mv $(trimArgs $targetTrashDir / $trashInfoName) /tmp
        mv -i $(trimArgs $targetTrashDir "/*") "$(dirname "$original_dir")"
    }

    delete_trash() {
        local dir=$1
        if ! $(hasValueq $dir); then dir="."; fi;
        loadArray   

        dir=$(pathGetFull $dir)

        trashFilter "original_dir" 'a(){ if $(echo $1 | grep -q'" $dir); then return 0; else return 1; fi; }; a"
        printTrashList 

        if [ ${#folder_data[@]} -lt 2 ]; then
            return $(_ERC "Error: empty, nothing to restore in $dir");
        fi;

        response=$(prompt "which one to delete ? [index:0]")

        if ! $(hasValueq ${folder_data[${response}_uuid]}); then return $(_ERC "index:$response does not exit"); fi;
        uuid=${folder_data[${response}_uuid]}

        targetTrashDir=$(trimArgs $TP / $uuid);
        rm -rf $targetTrashDir
    }

    index_trash() {
        loadArray
        length=${folder_data[length]}
        if ! $(hasValueq $1); then return $(_ERC "need target index"); fi;
        if [ $1 -gt $length ]; then echo "."; return $(_ERC "index [$1] larger than total length [$length]"); fi;

        for ((i=0; i<$length; i++)); do     
            if [ "${folder_data[${i}_index]}" = "$1" ]; then
                _EC $(trimArgs $TP / ${folder_data[${i}_uuid]});
                return 
            fi;
        done
    }

    clean_trash() {
        local seconds=7890000
        if $(hasValueq $1); then seconds=$1; fi;
        loadArray
        trashFilter "dtime" 'a(){ if $(dates -o "$@" "now"'" $seconds); then return 0; else return 1; fi; }; a "
        printTrashList 

        if [ "${#folder_data[@]}" -lt 2 ]; then
            return $(_RC 0 "Info: No available file found")
        fi
        
        response=$(prompt "clean these content in $TP ? (no) ")

        if [ $response -ne 1 ]; then
            return $(_RC 0 "clean not performed, exit clean")
        fi;

        length=${folder_data[length]}

        for ((i=0; i<$length; i++)); do     
            if $(hasValueq ${folder_data[${i}_uuid]}); then
                rmTarget=$(trimArgs $TP / ${folder_data[${i}_uuid]})
                _ED removing $rmTarget
                rm -rf $rmTarget
            fi;
        done

        _ED clean complete
    }

    purge_trash() {
        local response=$(prompt "purge all content in $TP ? (no) ")

        if [ $response -ne 1 ]; then
            return $(_RC 0 "purge not performed, exit purge")
        fi;

        rm -rf $TP;
        mkdir -p $TP;
        _ED purge complete
        
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$path"); then put_trash "$@"; 
    elif $(hasValueq "$list"); then list_trash $list; 
    elif $(hasValueq "$restore"); then restore_trash $restore; 
    elif $(hasValueq "$restoreIndex"); then restoreIndex_trash $restoreIndex; 
    elif $(hasValueq "$indexDir"); then index_trash $indexDir; 
    elif $(hasValueq "$clean"); then clean_trash $clean; 
    elif $(hasValueq "$delete"); then delete_trash $delete;
    elif $(hasValueq "$purge"); then purge_trash $purge; 
    fi;
}

# (...?pkgname)
## package update, or general update
upgrade() {
    local prefix="" m=$(os -p)
    if $(os -c linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if ! $(hasValue $@); then 
        _ED update packages list
        if [ "$m" = "yum" ]; then eval $(_EC "$prefix yum update -y");
        elif [ "$m" = "brew" ]; then eval $(_EC "brew update");
        elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get update -y");
        elif [ "$m" = "apk" ]; then eval $(_EC "$prefix apk update");
        elif [ "$m" = "pacman" ]; then eval $(_EC "$prefix pacman -Sy");
        elif [ "$m" = "dnf" ]; then eval $(_EC "$prefix dnf check-update");
        elif [ "$m" = "choco" ]; then eval $(_EC "choco upgrade all -y");
        elif [ "$m" = "winget" ]; then eval $(_EC "winget upgrade --all -y --accept-package-agreements --accept-source-agreements"); 
        fi; 
    else
        if [ "$m" = "yum" ]; then eval $(_EC "$prefix yum upgrade -y $@");
        elif [ "$m" = "brew" ]; then eval $(_EC "brew install $@");
        elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get upgrade -y $@");
        elif [ "$m" = "apk" ]; then eval $(_EC "$prefix apk upgrade $@");
        elif [ "$m" = "pacman" ]; then eval $(_EC "$prefix pacman -Syu --noconfirm $@");
        elif [ "$m" = "dnf" ]; then eval $(_EC "$prefix dnf upgrade -y $@");
        elif [ "$m" = "choco" ]; then eval $(_EC "choco upgrade -y $@");
        elif [ "$m" = "winget" ]; then eval $(_EC "winget upgrade --accept-package-agreements --accept-source-agreements $@"); 
        fi; 
    fi;
}

# (...pkgname): string
install() {
    local prefix="" m=$(os -p)
    if $(os -c linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if [ "$m" = "yum" ]; then eval $(_EC "$prefix yum install -y $@");
    elif [ "$m" = "brew" ]; then eval $(_EC "HOMEBREW_NO_AUTO_UPDATE=1 brew install $@");
    elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get install -y $@");
    elif [ "$m" = "apk" ]; then eval $(_EC "$prefix apk add $@");
    elif [ "$m" = "pacman" ]; then eval $(_EC "$prefix pacman -Syu --noconfirm $@");
    elif [ "$m" = "dnf" ]; then eval $(_EC "$prefix dnf install -y $@");
    elif [ "$m" = "choco" ]; then eval $(_EC "choco install -y $@");
    elif [ "$m" = "winget" ]; then eval $(_EC "winget install --accept-package-agreements --accept-source-agreements $@"); 
    fi;
}

# container clean install
installC() {
    local prefix="" m=$(os -p)
    if $(os -c linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if [ "$m" = "apk" ]; then eval $(_EC "$prefix apk add --no-cache $@");
    elif [ "$m" = "yum" ]; then eval $(_EC "$prefix yum install -y $@");
    elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $@"); 
    fi;
}

# container cleanup
cleanup() {
    local m=$(os -p)

    if [ "$m" = "apk" ]; then eval $(_EC "apk cache clean && rm -rf /tmp/*");
    elif [ "$m" = "yum" ]; then eval $(_EC "yum autoremove -y && yum clean all && rm -rf /var/cache/yum /tmp/*");
    elif [ "$m" = "apt" ]; then eval $(_EC "apt-get autoremove -y && apt-get clean && find /var/lib/apt/lists/ -type f ! -name 'sources.list' -delete && rm -rf /tmp/* /var/tmp/*"); 
    fi;
}

rmpkg() {
    local prefix="" m=$(os -p)
    if $(os -c linux) && $(hasCmd sudo); then prefix="sudo"; fi;

    if [ "$m" = "yum" ]; then eval $(_EC "$prefix yum autoremove -y $@");
    elif [ "$m" = "brew" ]; then eval $(_EC "brew uninstall $@");
    elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get autoremove -y $@");
    elif [ "$m" = "apk" ]; then eval $(_EC "$prefix apk del $@");
    elif [ "$m" = "pacman" ]; then eval $(_EC "$prefix pacman -Rns --noconfirm $@");
    elif [ "$m" = "dnf" ]; then eval $(_EC "$prefix dnf autoremove -y $@");
    elif [ "$m" = "choco" ]; then eval $(_EC "choco uninstall -y $@");
    elif [ "$m" = "winget" ]; then eval $(_EC "winget uninstall $@"); 
    fi;
}

# (length=10, ?useSymbol): string
password() {
    local length=${1:-10} symbol=$2 range='A-Za-z0-9'
    if ! [[ -z ${symbol} ]]; then range=$range.'!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'; fi;
    LC_ALL=C tr -dc $range </dev/urandom | head -c $length ; echo
}

encrypt() {
    if ! $(hasCmd gpg); then return $(_ERC "gpg not found"); fi; 
    if ! $(hasValueq $_U2_GPG_PW); then source ~/.bash_env; fi;
    if ! $(hasValueq $_U2_GPG_PW); then return $(_ERC "_U2_GPG_PW not present or set in bash_env"); fi;
    _ED using gpg to encrypt {$@}

    gpg --batch --passphrase "$_U2_GPG_PW" -c "$@"
}

decrypt() {
    if ! $(hasCmd gpg); then return $(_ERC "gpg not found"); fi;
    if ! $(hasValueq $_U2_GPG_PW); then source ~/.bash_env; fi;
    if ! $(hasValueq $_U2_GPG_PW); then return $(_ERC "_U2_GPG_PW not present or set in bash_env"); fi;
    _ED using gpg to decrypt {$@}
    gpg --batch --yes --passphrase "$_U2_GPG_PW" "$@"
}

# (gpg .sh file url) -> run local content 
decryptURL() {
    if ! $(hasValueq $_U2_GPG_PW); then source ~/.bash_env; fi;
    if ! $(hasCmd gpg); then return $(_ERC "gpg not found"); fi;
    if ! $(hasValueq $@); then return $(_ERC "No URL provided"); fi;
    
    local tmpfile=$(mktemp);
    local decryptedFile;
    if $(os mac); then decryptedFile=$(gmktemp --suffix=".sh"); else decryptedFile=$(mktemp --suffix=".sh"); fi;

    download "$@" "$tmpfile";
    if ! $(hasValueq $_U2_GPG_PW); then _U2_GPG_PW=$(promptSecret "Please enter your GPG passphrase: "); fi; 

    if ! gpg --batch --yes --passphrase "$_U2_GPG_PW" --decrypt < "$tmpfile" > "$decryptedFile"; then
        rm -f "$tmpfile" "$decryptedFile"
        return $(_ERC "Decryption failed. Please check your passphrase."); 
    fi; 

    rm -f $tmpfile
    chmod 777 $decryptedFile
    . $decryptedFile
    rm -f $decryptedFile
}

# shiftto "-p|--pattern" "-p abc -p d" -> "abc -p d"
shiftto() {
    local pattern="$1"
    local input="${@:2}"
    local regex="(^|[[:space:]])($pattern)([[:space:]]+|$)"

    _ED pattern {$pattern} input {$input}
    local last_match=$(echo "$input" | grep -o -E "$regex" | tail -n 1)    
    if [[ -n "$last_match" ]]; then
        local remaining="${input#*"${last_match}"}"
        _EC ${remaining#*${BASH_REMATCH[2]}}
    else
        return $(_ERC "pattern not found")
    fi
}

# shifttolast "-p|--pattern" "-p abc -p d" -> "d"
shifttolast() {
    local pattern="$1"
    local input="${@:2}"
    local regex="(^|[[:space:]])($pattern)([[:space:]]+|$)"

    _ED pattern {$pattern} input {$input}
    local last_match=$(echo "$input" | grep -o -E "$regex" | tail -n 1)
    if [[ -n "$last_match" ]]; then
        local remaining="${input#*"${last_match}"}"
        local last_word=$(echo "$remaining" | awk '{$1=""; print $0}' | xargs)
        _EC "${last_word##* }"
    else
        return $(_ERC "pattern not found")
    fi
}

# -e,--equal (string, string)
# -c,--contain (string, stringOrRegex)
# -r,--replace (string, string, string)
# -n,--number (string)
# -i,--index (...string, int)
string() {
    declare -A string_data; parseArg string_data $@;
    local equal=$(parseGet string_data e equal);
    local contain=$(parseGet string_data c contain);
    local replace=$(parseGet string_data r replace);
    local number=$(parseGet string_data n number);
    local index=$(parseGet string_data i index);
    local upper=$(parseGet string_data u upper);
    local lower=$(parseGet string_data l lower);
    local help=$(parseGet string_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-e,--equal \t (string,string) \t\t compare two strings\n'
    helpmsg+='\t-c,--contain \t (string,stringOrRegex) \t check if string contains, calling from other script should ensure quote bottom "$@" dispatch section \n'
    helpmsg+='\t-r,--replace \t (string,string,string) \t 1,original string; 2,search string, 3,replacement \n'
    helpmsg+='\t-n,--number \t (string) \t\t\t check if string is a number \n'
    helpmsg+='\t-i,--index \t (...string,int) \t\t treat string as array, get index of it \n'
    
    equal_string(){
        if [ "$1" = "$2" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    contain_string(){
        shift
        if [ "$#" -lt 2 ]; then return $(_RC 1 $@); fi;
        if $(echo "$1" | grep -q "$2"); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    replace_string(){
        local string=$1 search=$2 replace=$3
        echo "${string//$search/$replace}"
    }

    number_string() {
        local string=$1
        if [[ $string =~ ^[0-9]+$ ]]; then return $(_RC 0); else return $(_RC 1); fi;
    }

    index_string() {
        local index="${@: -1}"
        if [[ $index =~ ^[0-9]+$ ]]; then index=$(($index+1)); else return $(_ERC "index $index is not a number"); fi;

        echo "${@:$index:1}"
    }

    upper_string() {
        shift
        _EC $@ | tr '[:lower:]' '[:upper:]'
    }

    lower_string() {
        shift
        _EC $@ | tr '[:upper:]' '[:lower:]' 
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$equal"); then equal_string $equal;
    elif $(hasValueq "$contain"); then contain_string "$@";
    elif $(hasValueq "$replace"); then replace_string $replace;
    elif $(hasValueq "$number"); then number_string $number;
    elif $(hasValueq "$index"); then index_string $index;
    elif $(hasValueq "$upper"); then upper_string "$@"; 
    elif $(hasValueq "$lower"); then lower_string "$@"; 
    fi;

}

np() {
    https_proxy="" http_proxy="" HTTPS_PROXY="" HTTP_PROXY="" no_proxy="" NO_PROXY="" command $@
}

noproxy() {
    https_proxy="" http_proxy="" HTTPS_PROXY="" HTTP_PROXY="" no_proxy="" NO_PROXY="" command $@
}

_PROXY() {
    echo https_proxy="$1" http_proxy="$1" HTTPS_PROXY="$1" HTTP_PROXY="$1" 
}

# Request helper
# Need to specify $CURL:bool, $WGET:bool, curlCmd():func, wgetCmd():func
_REQHelper() {
    if [[ -z $CURL ]] && [[ -z $WGET ]]; then
        if $(hasCmd curl); then curlCmd; elif $(hasCmd wget); then wgetCmd; fi;
    else
        if ! [[ -z $CURL ]]; then _ED "curl command specified" && curlCmd;
        else _ED "wget command specified" && wgetCmd; fi; 
    fi;
    echo ""
}

# -u,--url,_ *_default
# -j,--json, *_2
# -s,--string post string
# -C,--curl use curl
# -W,--wget use wget
# -U,--ua new useragent
# -q,--quiet disable verbose
post() {
    declare -A post_data; parseArg post_data $@;
    local url=$(parseGet post_data u url _ D dns C curl W wget q quiet);
    local json=$(parseGet post_data j json);
    local string=$(parseGet post_data s string);
    local DNS=$(parseGet post_data D dns);
    local CURL=$(parseGet post_data C curl);
    local WGET=$(parseGet post_data W wget);
    local AGENT=$(parseGet post_data U ua);
    local quiet=$(parseGet post_data q quiet);
    local help=$(parseGet post_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-j,--json \t (string) \t json data to post\n'
    helpmsg+='\t-s,--string \t (string) \t string data to post\n'
    helpmsg+='\t-D,--dns \t () \t\t use DNS over HTTPS to request website\n'
    helpmsg+='\t-C,--curl \t () \t\t use curl\n'
    helpmsg+='\t-W,--wget \t () \t\t use wget\n'
    helpmsg+='\t-q,--quiet \t () \t\t disable verbose\n'

    if [[ -z $quiet ]]; then curlEx=" -v"; wgetEx="";
        if ! $(os -c alpine); then wgetEx=" -d"; fi;
    else curlEx=""; wgetEx=" -q"; fi;

    if $(hasValueq "$DNS"); then 
        curlEx+=" --doh-url https://cloudflare-dns.com/dns-query";
        CURL=true 
    fi;

    if $(hasValueq "$AGENT"); then
        if $(hasValueq $AGENT); then url=$AGENT; fi;
        local useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.3";
        local userHeaders=("Accept: text/*, application/*;q=0.8, image/*;q=0.6, video/*" "Accept-Language: en-US,en;q=0.5" "Accept-Encoding: gzip, deflate, br" "Connection: keep-alive")

        curlEx+=" -A \"$useragent\""
        wgetEx+=" --user-agent=\"$useragent\""

        for heads in "${userHeaders[@]}"
        do
        curlEx+=" -H \"$heads\""
        wgetEx+=" --header=\"$heads\""
        done
    fi;
        
    # (url, data)
    json_post(){
        local url=$1 data="${@:2}"
        curlCmd(){
            eval $(_EC curl $curlEx -H "\"Content-Type: application/json\"" -d "'"$data"'" "$url")
        }
        wgetCmd(){
            eval $(_EC wget $wgetEx -O- --header "\"Content-Type: application/json\"" --post-data "'"$data"'" "$url")
        }
        _REQHelper
    }

    # (url, data)
    string_post() {
        local url=$1 data="${@:2}"
        curlCmd(){
            eval $(_EC curl $curlEx -H "\"Content-Type: text/plain\"" -d \"$data\" "$url")
        }
        wgetCmd(){
            eval $(_EC wget $wgetEx -O- --header "\"Content-Type: text/plain\"" --post-data \"$data\" "$url")
        }
        _REQHelper
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$string"); then string_post $url "$string";
    elif $(hasValueq "$json"); then json_post $url "$json"; 
    else json_post $url; 
    fi;
}

# -u,--url,_ *_default
# -r,--run
# -C,--curl use curl
# -W,--wget use wget
# -U,--ua new useragent
# -q,--quiet disable verbose
get() {
    declare -A get_data; parseArg get_data $@;
    local url=$(parseGet get_data u url _ D dns C curl W wget q quiet);
    local run=$(parseGet get_data r run);
    local DNS=$(parseGet get_data D dns);
    local CURL=$(parseGet get_data C curl);
    local WGET=$(parseGet get_data W wget);
    local AGENT=$(parseGet get_data U ua);
    local quiet=$(parseGet get_data q quiet);
    local help=$(parseGet get_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-r,--run \t (string) \t run the script from url, can pass extra command, should be at the end\n'
    helpmsg+='\t-D,--dns \t () \t\t use DNS over HTTPS to request website\n'
    helpmsg+='\t-C,--curl \t () \t\t use curl\n'
    helpmsg+='\t-W,--wget \t () \t\t use wget\n'
    helpmsg+='\t-U,--ua \t () \t\t use new user agent\n'
    helpmsg+='\t-q,--quiet \t () \t\t disable verbose\n'
    
    if [[ -z $quiet ]]; then curlEx=" -v"; wgetEx="";
        if ! $(os -c alpine); then wgetEx=" -d"; fi;
    else curlEx=""; wgetEx=" -q"; fi;

    if $(hasValueq "$DNS"); then 
        curlEx+=" --doh-url https://cloudflare-dns.com/dns-query";
        CURL=true 
    fi;

    if $(hasValueq "$AGENT"); then
        if $(hasValueq $AGENT); then url=$AGENT; fi;
        local useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.3";
        local userHeaders=("Accept: text/*, application/*;q=0.8, image/*;q=0.6, video/*" "Accept-Language: en-US,en;q=0.5" "Accept-Encoding: gzip, deflate, br" "Connection: keep-alive")

        curlEx+=" -A \"$useragent\""
        wgetEx+=" --user-agent=\"$useragent\""
        
        for heads in "${userHeaders[@]}"; do
            curlEx+=" -H \"$heads\""
            wgetEx+=" --header=\"$heads\""
        done
    fi;

    # exArgs starts with "-"" will not be passed as whole string
    script_get() {
        remain=$(shiftto "-r|--run" $@); 
        local url=$(echo "$remain" | awk '{print $1}'); exArgs=$(echo "$remain" | cut -d' ' -f2-);
        curlCmd(){
            tmpfile=$(mktemp)
            curl -sSL $url -o $tmpfile
            _ED download finish, executing bash: url {$url} args {$exArgs}
            if [[ "$exArgs" == -* ]]; then bash $tmpfile $exArgs;
            else bash $tmpfile "$exArgs"; fi;
            rm -f $tmpfile
        }
        wgetCmd(){
            local wgetEx=""
            if ! $(os -c alpine); then wgetEx=" -d"; fi;
            tmpfile=$(mktemp)
            wget $wgetEx -O $tmpfile $url
            _ED download finish, executing bash: url {$url} args {$exArgs}
            if [[ "$exArgs" == -* ]]; then bash $tmpfile $exArgs;
            else bash $tmpfile "$exArgs"; fi;
            rm -f $tmpfile
        }
        _REQHelper
    }

    url_get(){
        local url=$1
        curlCmd(){
            eval $(_EC curl $curlEx -X GET $url)
        }
        wgetCmd(){
            eval $(_EC wget $wgetEx -O- $url)
        }
        _REQHelper
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$run"); then script_get $@;
    elif $(hasValueq "$url"); then url_get $url; 
    fi;
}

# (url, outputFileName?)
download() {
    local url=$1 filename="${@:2}"
    if $(hasCmd curl); then
        if $(hasValue $filename); then curl $url -v -L --output $filename; else curl -v -L -O $url; fi;
    elif $(hasCmd wget); then
        local wgetEx=""
        if ! $(os -c alpine); then wgetEx=" -d"; fi;
        if $(hasValue $filename); then wget $wgetEx -O $filename $url; else wget $wgetEx $url; fi; 
    fi;
}

# (string)
# retry command if failed; 3 times, can define "interval" or "retry" as env
retry() {
    if [ -z "$interval" ]; then interval=1; fi;
    if [ -z "$retry" ]; then retry=3; fi;

    while [[ $retry -ne 0 ]]; do
        _ED { retry: $retry remain, interval: $interval }
        output=$("$@");
        if [[ $? -eq 0 ]]; then
            if [ -n "$output" ]; then echo $output; fi;
            return $(_RC 0)
        else
            retry=$((retry - 1))
            sleep "$interval"
        fi
    done
    return $(_RC 1)
}

q(){
    if $(string -n $@); then quick -i $@; else quick $@; fi;
}

quick() {
    declare -A quick_data; parseArg quick_data $@;
    local name=$(parseGet quick_data n name _ e edit r remove delete c cat display show h has);
    local variable=$(parseGet quick_data v variable);
    local add=$(parseGet quick_data a add)
    local edit=$(parseGet quick_data e edit);
    local display=$(parseGet quick_data c cat display show)
    local remove=$(parseGet quick_data r remove delete);
    local list=$(parseGet quick_data l list);
    local index=$(parseGet quick_data i index);
    local hasName=$(parseGet quick_data h has);
    local help=$(parseGet quick_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t\t (string) \t *_default, + -e,--edit,-r,--remove,--delete name of the quick data\n'
    helpmsg+='\t-v,--variable \t\t\t (string) \t variable or args to use\n'
    helpmsg+='\t-a,--add \t\t\t (string) \t\t add command to name, can use $1 and args in script, and use quick -v to add to script call\n'
    helpmsg+='\t-e,--edit \t\t\t () \t\t edit the target file\n'
    helpmsg+='\t-c,--cat,--display,--show \t () \t\t display the content of file\n'
    helpmsg+='\t-r,--remove,--delete \t\t () \t\t remove the target file\n'
    helpmsg+='\t-l,--list \t\t\t () \t\t list total quick command\n'
    helpmsg+='\t-i,--index \t\t\t () \t\t directly perform action via index\n'

    name=$(echo $name | sed 's/ *//')
    targetFile="$_U2_Storage_Dir_Quick/$name"

    edit_quick(){
        if $(hasCmd nano); then nano $targetFile;
        elif $(hasCmd vi); then vi $targetFile; fi;
    }

    display_quick() {
        cat "$targetFile"
    }

    add_quick() {
        local sentence=""
        for ((i=1; i<=$#; i++)); do
            if [[ "${!i}" == "-a" || "${!i}" == "--add" ]]; then
                ((i++))
                sentence="${@:i}"
                break
            fi
        done
        local profile="$(_PROFILE)"
        printf "#!/usr/bin/env bash\nsource $profile\n$sentence\n" > $targetFile
        ls_quick
    }

    run_quick(){
        part1=$(echo $targetFile | cut -d ' ' -f 1 )
        part2=$(echo $targetFile | sed 's/.* *//')
        if $(hasValueq $variable); then variable=$(shiftto "-v|--variable" $@); fi;
        _ED content:{$(cat $part1)} part2{$part2} variable{$variable} 
        exec bash "$part1" "$part2" "$variable"
    }

    remove_quick(){
        if $(hasFile $targetFile); then trash $targetFile; fi;
    }

    has_quick() {
        return $(hasFile $targetFile);
    }

    ls_quick() {
        dir_array=()
        cd $_U2_Storage_Dir_Quick
        for name in *; do
            if [[ -e "$name" ]]; then
                dir_array+=("$name")
            fi
        done

        for i in "${!dir_array[@]}"; do
            echo "[$i]: ${dir_array[$i]}"
        done
    }

    index_quick() {
        if ! $(string -n $@); then return $(_ERC "index not a number"); fi;
        dir_array=()
        cd $_U2_Storage_Dir_Quick
        for name in *; do
            if [[ -e "$name" ]]; then
                dir_array+=("$name")
            fi
        done
        name=${dir_array[$@]}
        _ED executing quick {$name}
        targetFile="$_U2_Storage_Dir_Quick/$name"
        run_quick
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$list"); then ls_quick "$list";
    elif $(hasValueq "$index"); then index_quick "$index";
    elif ! $(hasValueq "$name"); then return $(_ERC "name not specified"); 
    elif $(hasValueq "$add"); then add_quick "$@";
    elif $(hasValueq "$edit"); then edit_quick "$edit";
    elif $(hasValueq "$display"); then display_quick "$display";
    elif $(hasValueq "$remove"); then remove_quick "$remove";
    elif $(hasValueq "$hasName"); then has_quick "$hasName";
    else run_quick "$@"; 
    fi;
}

# acquire the lock
# if ! _LON "$file"; then return $(_ERC "failed"); fi;
# _LOFF "$file"
_LON() {
    local lockfile="/tmp/$(basename "$1").lock"
    local timeout=10
    local waitTime=1
    local elapsed=0

    exec 200>"$lockfile"

    while ! ln "$lockfile" "$lockfile.lock" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout" ]; then
             return $(_ERC "Could not acquire lock after $timeout seconds for $filePath")
        fi
        sleep "$waitTime"
        elapsed=$((elapsed + waitTime))
    done
    _ED "lock acquired + {$lockfile}"
}

# release the lock
_LOFF() {
    local lockfile="/tmp/$(basename "$1").lock"
    rm "$lockfile.lock"
    exec 200>&-
    _ED "lock released - {$lockfile}"
}

subdir() {
    declare -A subdir_data; parseArg subdir_data $@;
    local perform=$(parseGet subdir_data p perform);
    local target=$(parseGet subdir_data t target);
    local skip=$(parseGet subdir_data s skip);
    local help=$(parseGet subdir_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--perform,_ \t (string) \t put perform at the end to execute full command\n'
    helpmsg+='\t-t,--target \t (string) \t default to current dir\n'
    helpmsg+='\t-s,--skip \t (string) \t default to .git and node_modules\n'

    if ! $(hasValueq $target); then target="$(pwd)"; fi;
    if $(hasValueq $perform); then 
        action=$(shiftto "-p|--perform" $@);
        if ! $(hasValueq $action); then action=$@; fi; 
    fi;

    perform_subdir(){
        skip+=" .git node_modules"
        _ED skipping {$skip}
        IFS=' ' read -ra skipArray <<< "$skip"
        grepExclude=""

        for folder in "${skipArray[@]}"; do
            grepExclude+=" -e /$folder"
        done
        
        filteredResult=$(find $(realpath $target) -mindepth 1 -maxdepth 1 -type d | grep -v $grepExclude)
        _ED TARGET Subdir List: {$filteredResult}

        for subfolder in $filteredResult; do
            _ED START perform action in {$subfolder}
            ( cd "$subfolder"; eval "$action"; )
            _ED END perform action in {$subfolder}, exitcode {$?}
        done
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$action"); then perform_subdir $action; 
    fi;
    
}

# call setup bash beforehand
setup() {
    local profile="$(_PROFILE)"
    mkdir -p ~/Documents
    mkdir -p $_U2_Storage_Dir_Bin && mkdir -p $_U2_Storage_Dir_Quick && mkdir -p $_U2_Storage_Dir_Trash

    if ! $(hasFile "$HOME/.bash_mine"); then
        touch $HOME/.bash_mine && touch $HOME/.bash_env
        echo 'source $HOME/.bash_mine' >> $profile
        echo 'source $HOME/.bash_env' >> $HOME/.bash_mine
        
        echo 'if [ "$PWD" = "$HOME" ]; then cd Documents; fi;' >> $HOME/.bash_mine
        echo 'PATH=$HOME/.npm_global/bin:'$_U2_Storage_Dir_Bin':$PATH' >> $HOME/.bash_mine
        echo 'function cdd { _back=$(pwd) && cd $@ && ls -a; }' >> $HOME/.bash_mine
        echo 'function cdb { _oldback=$_back && _back=$(pwd) && cd $_oldback && ls -a; }' >> $HOME/.bash_mine
        echo '_U_CD_DIR=()' >> $HOME/.bash_mine
        echo 'function cdr { if ! [[ -z $1 ]]; then cd $@ && ls -a; fi; _U_CD_DIR+=("$(pwd)"); }' >> $HOME/.bash_mine
        echo 'function cdt { if [[ -z $1 ]]; then for i in "${!_U_CD_DIR[@]}"; do echo "$i: ${_U_CD_DIR[$i]}"; done; else cd "${_U_CD_DIR[$@]}" && ls -a; fi; }' >> $HOME/.bash_mine

        printf 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\nexport NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\n\n' >> $HOME/.bash_mine 
        printf 'if [[ ! -z "$u_proxy" ]] && curl --output /dev/null --silent --head "$u_proxy"; then\n export https_proxy=$u_proxy\n export http_proxy=$u_proxy\n export HTTPS_PROXY=$u_proxy\n export HTTP_PROXY=$u_proxy\nfi;\n'  >> $HOME/.bash_mine
        echo "alias trash='u trash'" >> $HOME/.bash_mine

        echo '_U2_GPG_PW=' >> $HOME/.bash_env

        if $(os -c alpine); then profile="/etc/profile"; echo 'source $HOME/.bash_mine' >> $profile; fi;
        if $(os -c mac); then printf 'export BASH_SILENCE_DEPRECATION_WARNING=1\n' >> $HOME/.bash_mine; fi; 
    fi;

    cp $(_SCRIPTPATHFULL) $_U2_Storage_Dir_Bin/u2
    cp $(_SCRIPTPATHFULL) $_U2_Storage_Dir_Bin/u
    $_U2_Storage_Dir_Bin/u2 _ED Current Version: $($_U2_Storage_Dir_Bin/u2 version)
    if [ -w /usr/bin ] && $(has -d /usr/bin); then exec cp -f $_U2_Storage_Dir_Bin/u /usr/bin/u 2>/dev/null; fi;
}

setupEX() {
    declare -A setupex_data; parseArg setupex_data $@;
    local nodeAdd=$(parseGet setupex_data n node);
    local bunAdd=$(parseGet setupex_data b bun);
    local pm2Add=$(parseGet setupex_data p pm2);
    local dockerAdd=$(parseGet setupex_data d docker);
    local containerAdd=$(parseGet setupex_data c container);
    local allAdd=$(parseGet setupex_data a all);
    local sourceAdd=$(parseGet setupex_data s source);
    local help=$(parseGet setupex_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--node \t () \t add node to setup\n'
    helpmsg+='\t-b,--bun \t () \t add bun to setup\n'
    helpmsg+='\t-p,--pm2 \t () \t add pm2 to setup\n'
    helpmsg+='\t-d,--docker \t () \t add docker to setup\n'
    helpmsg+='\t-a,--all \t () \t add all except container\n'
    helpmsg+='\t-s,--source \t () \t only setup source\n'
    helpmsg+='\t-c,--container \t () \t container repo and slim package setup\n'

    source_setupEx() {
        if ! $(hasValue $_U2_INIT_DEP); then
            
            if grep -q "ID=ubuntu" /etc/os-release ; then 
                codename=$(sh -c '. /etc/os-release; echo $VERSION_CODENAME')
                _ED updating ubuntu $codename mirror
                printf "deb http://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse
\ndeb-src http://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse
\ndeb http://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse
\ndeb-src http://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse
\ndeb http://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
\ndeb-src http://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
\ndeb http://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse
\ndeb-src http://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse
        " > /etc/apt/sources.list
            fi;

            if grep -q "ID=debian" /etc/os-release ; then
                codename=$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')
                _ED updating debian $codename mirror
                printf "deb http://mirrors.163.com/debian/ $codename main contrib non-free
\ndeb-src http://mirrors.163.com/debian/ $codename main contrib non-free
\ndeb http://mirrors.163.com/debian/ $codename-updates main contrib non-free
\ndeb-src http://mirrors.163.com/debian/ $codename-updates main contrib non-free
\ndeb http://mirrors.163.com/debian/ $codename-backports main contrib non-free
\ndeb-src http://mirrors.163.com/debian/ $codename-backports main contrib non-free
\ndeb http://mirrors.163.com/debian-security/ $codename-security main contrib non-free
\ndeb-src http://mirrors.163.com/debian-security/ $codename-security main contrib non-free
" > /etc/apt/sources.list
            fi;

            if grep -q "ID=alpine" /etc/os-release ; then
                _ED updating alpine mirror
                printf "https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main
\nhttps://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community
        " > /etc/apk/repositories
            fi;

            upgrade
            defaultPKG="wget curl ca-certificates bash"
            if $(hasValueq $containerAdd); then 
                _ED "use {installC} to install & {cleanup} for final cleanup"
                installC $defaultPKG; 
            else install $defaultPKG; fi;
            setup
            if $(has -f /etc/apt/sources.list); then sed -i 's|http://|https://|g' /etc/apt/sources.list; fi; 
        fi;
    }
  
    install_setupEx() {
        local extraArgs=""
        if $(hasValueq "$nodeAdd"); then extraArgs="$extraArgs node"; fi;
        if $(hasValueq "$bunAdd"); then extraArgs="$extraArgs bun"; fi;
        if $(hasValueq "$pm2Add"); then extraArgs="$extraArgs pm2"; fi;
        if $(hasValueq "$dockerAdd"); then extraArgs="$extraArgs docker"; fi;
        if $(hasValueq "$containerAdd"); then extraArgs="$extraArgs container"; fi;
        if $(hasValueq "$allAdd"); then extraArgs="$extraArgs ALL"; fi;
        _ED extraArgs: "$extraArgs"

        source_setupEx

        setupURL="https://hub.gitmirror.com/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" 
        get -r $setupURL "$extraArgs"
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$sourceAdd"); then source_setupEx; 
    else install_setupEx; 
    fi;
}

# (string)
# edit path, else edit current script
edit(){
    local editPath=$(_SCRIPTPATHFULL)
    if $(hasValue "$@"); then editPath="$@"; fi;

    if $(hasCmd code); then code $editPath;
    elif $(hasCmd nano); then nano $editPath;
    elif $(hasCmd vi); then vi $editPath; fi;
}

help(){    
    declare -A help_data; parseArg help_data $@;
    local name=$(parseGet help_data n name _);
    local update=$(parseGet help_data u update upgrade);
    local updateForce=$(parseGet help_data U Update);
    local version=$(parseGet help_data v version);
    local edit=$(parseGet help_data e edit);
    local help=$(parseGet help_data h help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t (string) \t grep functions with name\n'
    helpmsg+='\t-u,--update,--upgrade \t () \t\t upgrade current script\n'
    helpmsg+='\t-U,--Update \t\t () \t\t upgrade current script from source\n'
    helpmsg+='\t-v,--version \t\t (string) \t display current version\n'
    helpmsg+='\t-e,--edit \t\t () \t\t edit the file\n'
    helpmsg+='\t-h,--help \t\t (string) \t display help message\n'

    update_help() {
        _ED Current Version: $(version)
        local updateUrl;
        if $(hasValueq "$update"); then 
            updateUrl="https://hub.gitmirror.com/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh"
        else 
            updateUrl="https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh"
        fi; 

        local tmpfile=$(mktemp)
        if $(hasCmd curl); then curl -sSL $updateUrl --output $tmpfile
        elif $(hasCmd wget); then wget -O $tmpfile $updateUrl
        fi;

        chmod 777 $tmpfile 
        exec $tmpfile setup 
    }

    edit_help() {
        edit
    }

    list_help() {
        if ! [[ -z $1 ]]; then compgen -A function | grep $1; else compgen -A function; fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$name"); then list_help $name;
    elif $(hasValueq "$update"); then update_help $update;
    elif $(hasValueq "$updateForce"); then update_help $updateForce;
    elif $(hasValueq "$version"); then echo $(version);
    elif $(hasValueq "$edit"); then edit_help;
    else $(list_help); 
    fi;
    
}

# --- EXTRA ---

open() { 
    declare -A open_data; parseArg open_data $@;
    local target=$(parseGet open_data t target _);
    local app=$(parseGet open_data a app);
    local help=$(parseGet open_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-t,--target,_ \t (string) \t open target\n'
    helpmsg+='\t-a,--app \t (string) \t open app by given partial name\n'
   
    target_open() {
        if $(os mac); then /usr/bin/open $@; elif $(os win); then start $@; else xdg-open $@; fi;
    }

    app_open() {
        if $(os mac); then
            name=$(trimArgs $@);
            pattern="*$name*.app"
            app_path=$(find /Applications -maxdepth 1 -iname "$pattern" | head -n 1)

            if [ -z "$app_path" ]; then return $(_ERC "Error, No matching application found {$pattern}"); fi;
            _ED "Opening application: {$app_path}"
            /usr/bin/open "$app_path"
        fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$target"); then target_open "$target"; 
    elif $(hasValueq "$app"); then app_open "$app"; 
    fi;
}

# portscan
# (string, int?) as ip, port
scan() {
    local scanIp=$1 scanPort=$2

    if ! $(hasValue $scanIp); then return $(_ERC "ip not defined"); fi;
    if ! $(hasValue $scanPort); then 
        _ED "port not present, scanning from 1 to 65535"
        echo "--- OPEN ---"
        for scanPort in {1..65535}; do nc -z -w1 $scanIp $scanPort && echo "$scanPort"; done;
    else nc -z -w1 $scanIp $scanPort && echo "$scanPort OPEN"; fi;
}

# portinfo on current machine
# -p,--port,--process,_ *_default
# -d,--docker (string)
# -i,--info (int)
port() { 
    declare -A port_data; parseArg port_data $@;
    local processPort=$(parseGet port_data p port process _);
    local dockerPort=$(parseGet port_data d docker);
    local infoPort=$(parseGet port_data i info);
    local killPort=$(parseGet port_data k kill);
    local help=$(parseGet port_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--port,--process,_ \t (string) \t use port number or process name to grep port info\n'
    helpmsg+='\t-d,--docker \t\t (string) \t use port number or process name to grep docker port info\n'
    helpmsg+='\t-i,--info \t\t (int) \t find info with target port number \n'
    helpmsg+='\t-k,--kill \t\t (int) \t find pid of target port, and kill it \n'

    process_port() {
        local grepTarget="$1"
        if ! $(hasValue $grepTarget); then
            if $(os linux); then netstat -plntu;
            elif $(os mac); then netstat -Watnlv | grep LISTEN | awk '{"ps -o comm= -p " $9 | getline procname; print cred "proto: " $1 " | addr.port: "$4 " | pid: "$9 " | name: " procname;  }' | column -t -s "|";
            elif $(os win); then netstat -bn; fi;
        else 
            if $(os linux); then netstat -plntu | grep $grepTarget; 
            elif $(os mac); then netstat -Watnlv | grep LISTEN | awk '{"ps -o comm= -p " $9 | getline procname; print cred "proto: " $1 " | addr.port: "$4 " | pid: "$9 " | name: " procname;  }' | column -t -s "|" | grep $grepTarget;
            elif $(os win); then netstat -bn | grep $grepTarget; fi; 
        fi;
    }

    docker_port() {
        local grepTarget="$1"
        if ! $(hasValue $grepTarget); then docker ps --format "{{.Ports}}\t:\t{{.Image}}";
        else docker ps | grep $grepTarget; fi;
    }

    info_port() {
        local portNum="$1"
        if ! $(hasValue $portNum); then return $(_ERC "port number not specified"); fi;
        
        local checkOpen=$(nc -z -w1 0.0.0.0 $portNum 2>/dev/null && echo "OPEN" || echo "")
        if ! $(hasValue $checkOpen); then return $(_ERC "port: $portNum closed"); fi;

        local infoResult="---netstat---\n$(process_port $portNum)\n"
        if $(hasCmd docker); then infoResult="$infoResult\n---docker---\n$(docker_port $portNum)\n"; fi;
        if $(hasCmd lsof); then infoResult="$infoResult\n---lsof---\n$(lsof -i :$portNum)\n"; fi;
        echo -e "$infoResult"
    }

    kill_port() {
        local portNum="$1" pidNum=""
        if ! $(hasValue $portNum); then return $(_ERC "port number not specified"); fi;
    
        if $(os linux); then pidNum=$(netstat -tlnp 2>/dev/null | grep ":$portNum " | awk -F '[ /]' '{print $7}' | head -n1);
        elif $(os mac); then pidNum=$(lsof -nP -iTCP:"$portNum" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $2; exit}');
        elif $(os win); then pidNum=$(netstat -ano | grep ":$portNum " | awk '{print $5}' | head -n1); fi; 
        
        if ! $(hasValue $pidNum); then return $(_ERC "pid missing, port number not found"); fi;
        pid $pidNum;
        promptResult=$(prompt "kill pid {$pidNum} ? (N/y)");
        if [ "$promptResult" -eq 1 ]; then process -k $pidNum; fi;
    }
    

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$processPort"); then process_port $processPort;
    elif $(hasValueq "$dockerPort"); then docker_port $dockerPort;
    elif $(hasValueq "$infoPort"); then info_port $infoPort;
    elif $(hasValueq "$killPort"); then kill_port $killPort;
    else process_port; 
    fi;
}

# auto log rotation 
logfile() {
    declare -A logfile_data; parseArg1 logfile_data $@;
    local file=$(parseGet logfile_data f file);
    local line=$(parseGet logfile_data l line);
    local message=$(parseGet logfile_data m message);
    local command=$(parseGet logfile_data c command);
    local command2=$(parseGet logfile_data c2 command2);
    local help=$(parseGet logfile_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-f,--file \t (string) \t file destination that you want to log to \n'
    helpmsg+='\t-l,--line \t (int) \t\t loose check mode, number of lines to keep in the file \n'
    helpmsg+='\t-m,--message \t (string) \t message to put in a log \n'
    helpmsg+='\t-c,--command \t (string) \t command to operate, log result to file \n'
    helpmsg+='\t-c2,--command2 \t (string) \t command to operate, include 2>&1, log result to file \n'

    perform_logfile() {

        if ! $(hasValue "$line"); then line=1000; fi;
        if ! $(hasValue $file); then return $(_ERC "file destination not specified"); else file=$(eval echo "$file"); fi;
        local indicator=""

        if $(hasValueq $command); then 
            string=$(shiftto "-c|--command" $@);
            indicator="-c, <$string>"
            content=$(eval "$string"); 
        fi;
        
        if $(hasValueq $command2); then 
            string=$(shiftto "-c2|--command2" $@);
            indicator="-c2, <$string>"
            content=$(eval "$string" 2>&1); 
        fi;

        if $(hasValueq $message); then 
            indicator="--message"
            content=$(shiftto "-m|--message" $@); 
        fi;

        if ! _LON "$file"; then return $(_ERC "failed"); fi;

        if $(has -F $file); then fileLine=$(wc -l < $file); else fileLine=0; fi; 
        _ED loose mode enabled, file line {$fileLine}, max {$line} 
        echo "$(_UTILDATE),$indicator; $content" >> $file
        if (( fileLine > line )); then 
            limit=$(( line / 2 )); 
            _ED limit reached, trimming to {$limit}
            temp_file=$(mktemp);  
            tail -n $limit $file > "$temp_file";  
            mv "$temp_file" $file; 
        fi; 
        _LOFF "$file"; 
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    else perform_logfile $@; 
    fi;
}

# -h,--head,_
# -m,--moveLocal (name, commitID)
# -M,--moveCloud (name, commitID)
# -i,--info
git() {
    declare -A git_data; parseArg git_data $@;
    local head=$(parseGet git_data h head _);
    local moveLocal=$(parseGet git_data m moveLocal);
    local moveCloud=$(parseGet git_data M moveCloud);
    local gitInfo=$(parseGet git_data i info);
    local help=$(parseGet git_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-h,--head,_ \t (string) \t\t transfer head to target location\n'
    helpmsg+='\t-m,--moveLocal \t (string,string) \t move local branch to target id, require: [ name, commitID ] \n'
    helpmsg+='\t-M,--moveCloud \t (string) \t move cloud Reference to target id, require: [ name, commitID ] \n'
    helpmsg+='\t-i,--info \t (string) \t\t display change status\n'

    unset -f git;
    local GIT=$(which git);

    adog_git() {
        $GIT log --all --decorate --oneline --graph
    }

    head_git() {
        $GIT restore . && $GIT checkout $@;
    }

    moveLocal_git() {
        local name=$(string -i $@ 0); commitID=$(string -i $@ 1);
        if ! $(hasValue $name); then return $(_ERC "name undefined, \'$@\'"); fi;
        if ! $(hasValue $commitID); then return $(_ERC "commitID undefined, \'$@\'"); fi;

        _ED move local: $name to $commitID 
        $GIT checkout $name && $GIT reset --hard $commitID
    }

    moveCloud_git() {
        local name=$(string -i $@ 0); commitID=$(string -i $@ 1);
        if ! $(hasValue $name); then return $(_ERC "name undefined, \'$@\'"); fi;
        if ! $(hasValue $commitID); then return $(_ERC "commitID undefined, \'$@\'"); fi;

        _ED move cloud: $name to $commitID 
        $GIT push --force origin $commitID:refs/heads/$name
    }

    info_git() {
        $GIT status
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$head"); then head_git $head;
    elif $(hasValueq "$moveLocal"); then moveLocal_git $moveLocal;
    elif $(hasValueq "$moveCloud"); then moveCloud_git $moveCloud; 
    elif $(hasValueq "$gitInfo"); then info_git $gitInfo; 
    else adog_git; 
    fi;
}

# (string)
# read from .bash_env and clone to defined location
gitclone() {
    source $HOME/.bash_env
    if ! $(hasValue $_U2_GIT_USER); then 
        _U2_GIT_USER=$(promptString enter default git username);
        echo '_U2_GIT_USER='$_U2_GIT_USER >> $HOME/.bash_env
    fi;
    if ! $(hasValue $_U2_GIT_CLONE_TO_DIR); then 
        _ED _U2_GIT_CLONE_TO_DIR not defined, defaut to ~/Documents, edit in bash_env
        _U2_GIT_CLONE_TO_DIR=~/Documents
        echo '_U2_GIT_CLONE_TO_DIR=~/Documents' >> $HOME/.bash_env
    fi;
    
    unset -f git;
    local GIT=$(which git);
    $GIT clone "https://github.com/$_U2_GIT_USER/$@.git" "$_U2_GIT_CLONE_TO_DIR/$@"
}

# open web for test
# -p,--port,_ *_default (int)
# -m,--message (string)
# -r,--redirect (URL)
_web() {
    declare -A _web_data; parseArg _web_data $@;
    local webPort=$(parseGet _web_data p port _);
    local webMessage=$(parseGet _web_data m message s string);
    local webRedirect=$(parseGet _web_data r redirect)
    local webDirectory=$(parseGet _web_data d dir);
    local webHtml=$(parseGet _web_data h html w web);
    local help=$(parseGet _web_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--port,_ \t\t\t (int) \t\t open server port, default port 3000\n'
    helpmsg+='\t-m,--message,-s,--string \t (string) \t message to display \n'
    helpmsg+='\t-r,--redirect \t\t\t (string) \t redirect to target URL \n'
    helpmsg+='\t-d,--dir \t\t\t (string) \t directory server with bun default "." \n'
    helpmsg+='\t-h,--html,-w,--web \t\t\t (string) \t html server with bun default "index.html" \n'

    if ! $(hasValue $webPort); then webPort=3000; fi;
    if ! $(hasValue $webMessage); then webMessage="web message"; fi;

    server_web() {
        local lip=$(ip -P)
        if $(hasCmd bun); then
            _ED Starting bun server on $lip:$webPort 

            if $(hasValueq $webMessage); then 
                bun -e "Bun.serve({port: $webPort,async fetch(req) {console.log(req);try{return new Response('$webMessage',{ status: 200 })}catch(e){console.log(e);}},})"
            else
                bun -e "Bun.serve({port: $webPort,async fetch(req) {console.log(req);try{return new Response(JSON.stringify({ method: req.method, url: req.url, headers: req.headers, body: await req.text()}))}catch(e){console.log(e);}},})"
            fi; 
            return
        fi;

        local webcmd=""
        if $(os mac); then webcmd="nc -l $webPort -k";
        else webcmd="nc -l -p $webPort -k"; fi;

        _ED Starting to open test web on $lip:$webPort
        echo -e "HTTP/1.1 200 OK\r\n\r\n$webMessage" | $webcmd
    }

    redirect_web() {
        local webcmd="" weblocation=$@
        local lip=$(ip -P); 

        if ! $(hasValueq $weblocation); then return $(_ERC "web redirect url not defined"); fi;
        
        local reHost=$(echo "$weblocation" | sed -E 's#^(https?://)?([^:/]+).*#\1\2#'); 
        local rePort=$(echo "$weblocation" | sed -E 's#^.*:([0-9]+)$#\1#'); 

        if [[ $weblocation != http://* && $weblocation != https://* ]]; then weblocation="http://$weblocation"; fi;
        
        if $(hasCmd bun); then 
            _ED Starting bun server redirect on $lip:$webPort to location: $weblocation
            bun -e "Bun.serve({port: $webPort,async fetch(req){console.log(req);return Response.redirect(\"$weblocation\", 301);}})"; 
            return
        fi;

        if $(os mac); then webcmd="nc -l $webPort -k";
        else webcmd="nc -l -p $webPort -k"; fi;

        _ED Starting to redirect on $lip:$webPort to location: $weblocation, as \' nc $reHost $rePort \'
        echo -e "HTTP/1.1 301 Moved Permanently\r\nLocation: $weblocation\r\n\r\n" | $webcmd > >(nc $reHost $rePort)
    }

    directory_web() {
        local servePath=$@
        if ! $(hasValueq $servePath); then servePath="."; fi;
        
        local lip=$(ip -P)
        _ED Starting bun file server on $lip:$webPort with path: \'$servePath\'

        bun -e " Bun.serve({ port: $webPort, fetch(req) {
        const url = new URL(req.url);
        const filePath = require('path').resolve(\`$servePath\`, url.pathname.slice(1));
        return require('fs/promises').stat(filePath).then(stats => stats.isDirectory() 
            ? require('fs/promises').readdir(filePath).then(files => Promise.all(files.map(file => require('fs/promises').stat(require('path').join(filePath, file)).then(stats=>stats.isDirectory() ? file + '/' : file))).then(formattedFiles => new Response(formattedFiles.join('\n'))))
            : require('fs/promises').readFile(filePath).then(content => new Response(content, { headers: { 'Content-Disposition':'attachment; filename=\"'+url.pathname.split('/').pop()+'\"' } }))
        ).catch(() => new Response('Not Found', { status: 404 }));},});"
    }

    html_web() {
        local servePath=$@
        if ! $(hasValueq $servePath); then servePath="."; fi;

        local lip=$(ip -P)
        _ED Starting bun html server on $lip:$webPort with path: \'$servePath\'

        bun -e "Bun.serve({port: $webPort, fetch(req) {
        const url = new URL(req.url); 
        const filePath = require('path').resolve(\`$servePath\`, url.pathname.slice(1) || 'index.html'); 
        return require('fs/promises').stat(filePath).then(stats => stats.isDirectory() 
            ? require('fs/promises').readFile(require('path').join(filePath, 'index.html')).then(content => new Response(content, {headers: {'Content-Type': 'text/html'}})) 
            : require('fs/promises').readFile(filePath).then(content => new Response(content, {headers: {'Content-Type': 'text/html'}}))
        ).catch(() => new Response('Not Found', {status: 404}));}});"
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$webRedirect"); then redirect_web $webRedirect;
    elif $(hasValueq "$webDirectory"); then directory_web $webDirectory;
    elif $(hasValueq "$webHtml"); then html_web $webHtml;
    else server_web; 
    fi;
}

# (string) base64 encode
b64e() {
    echo $@ | base64
}

#(string) base64 decode
b64d() {
    echo $@ | base64 -d
}

network() {
    declare -A network_data; parseArg network_data $@;
    local v2=$(parseGet network_data 2);
    local dns=$(parseGet network_data d dns);
    local help=$(parseGet network_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-2 \t\t (int) \t\t show iftop network, default show nethogs \n'
    helpmsg+='\t-d,--dns \t () \t\t show current dns \n'
  
    dns_network() {
        if $(os mac); then scutil --dns; 
        elif $(hasCmdq resolvectl); then resolvectl dns; 
        else cat /etc/resolv.conf; fi;
    }

    display_network() {
        if $(hasCmd nethogs) && ! $(hasValueq "$v2"); then 
            nethogs -C || nethogs; 
        elif $(hasCmd iftop); then
            iftop -b -P; 
        fi
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$dns"); then dns_network $dns;
    else display_network; 
    fi;
}

pid() {
    local input="$@"
    if $(hasValueq $input); then
        if $(os -c mac); then 
            if $(string -n $input); then 
                pstree -p $input;
            else 
                pstree -spa | grep $input; 
            fi;
            lsof -a -i -n -P -p $input;
        else 
            if $(string -n $input); then pstree -laps $input;
            else pstree -spa | grep $input; 
            fi; 
            port 2>/dev/null $input; 
        fi; 
    else
        if $(os -c mac); then pstree -w;
        else pstree -spa; 
        fi; 
    fi; 
}

service() { 
    declare -A service_data; parseArg service_data $@;
    local name=$(parseGet service_data n name _);
    local active=$(parseGet service_data a active);
    local restart=$(parseGet service_data r restart start);
    local stop=$(parseGet service_data s stop);
    local enable=$(parseGet service_data e enable);
    local disable=$(parseGet service_data d disable);
    local help=$(parseGet service_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t (string) \t display the target service status \n'
    helpmsg+='\t-a,--active \t\t () \t\t display the active service \n'
    helpmsg+='\t-r,--restart,--start \t (string) \t stop and then start the target service, limited \n'
    helpmsg+='\t-s,--stop \t\t (string) \t\t stop the target service, limited \n'
    helpmsg+='\t-e,--enable \t\t (string) \t\t start and enable the target service, limited \n'
    helpmsg+='\t-d,--disable \t\t (string) \t\t stop and disable the target service, limited \n'

    detail_service() {
        local serviceName=$@
        if $(hasCmd systemctl); then systemctl status "$serviceName";
        elif $(hasCmd rc-service); then rc-service "$serviceName" status;
        elif $(hasCmd launchctl); then launchctl list "$serviceName";
        elif $(os -c win); then sc query "$serviceName"; 
        fi; 
    }

    list_service() {
        if $(hasCmd systemctl); then systemctl list-units --type service;
        elif $(hasCmd rc-status); then rc-status --servicelist;
        elif $(hasCmd launchctl); then launchctl list;
        elif $(os -c win); then sc query state=all; 
        fi; 
    }

    active_service() {
        if $(hasCmd systemctl); then systemctl list-units --type service -a --state=active;
        elif $(hasCmd rc-status); then rc-status -a | grep started;
        elif $(hasCmd launchctl); then launchctl list | grep -v '^-';
        elif $(os -c win); then sc query state=active; 
        fi; 
    }

    _fetch_service() {
        local serviceName=$@
        if $(hasCmd systemctl); then promptSelect "choose your target service:" $(systemctl list-units --type service | grep $serviceName | awk '{print $1}'); 
        elif $(hasCmd rc-status); then promptSelect "choose your target service:" $(rc-status | grep $serviceName); 
        fi;
    }

    stop_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl stop $serviceName;
        elif $(hasCmd rc-service); then rc-service stop $serviceName;
        else _ED "SKIP, LIMITED"; 
        fi; 
    }

    restart_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then 
            systemctl stop $serviceName;
            systemctl start $serviceName;
        elif $(hasCmd rc-service); then 
            rc-service stop $serviceName;
            rc-service start $serviceName; 
        else _ED "SKIP, LIMITED"; 
        fi; 
    }

    enable_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl start $serviceName && systemctl enable $serviceName;
        elif $(hasCmd rc-update); then rc-service start $serviceName && rc-update add $serviceName default; 
        else _ED "SKIP, LIMITED"; 
        fi; 
    }

    disable_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl stop $serviceName || systemctl disable $serviceName;
        elif $(hasCmd rc-update); then rc-service stop $serviceName || rc-update del $serviceName default; 
        else _ED "SKIP, LIMITED"; 
        fi; 
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq $name); then detail_service $name;
    elif $(hasValueq "$active"); then active_service "$active";
    elif $(hasValueq "$stop"); then stop_service "$stop";
    elif $(hasValueq $restart); then restart_service $restart;
    elif $(hasValueq $enable); then enable_service $enable;
    elif $(hasValueq $disable); then disable_service $disable;
    else list_service; 
    fi;
}

# --info, _ (string)
# -s,--cpu
# -S,--mem
# -p,--parent (int)
# -l,--line (10)
process() { 
    declare -A process_data; parseArg process_data $@;
    local grepInfo=$(parseGet process_data info _ k kill);
    local sortCPU=$(parseGet process_data s cpu);
    local sortMEM=$(parseGet process_data S mem);
    local parent=$(parseGet process_data p parent);
    local hasit=$(parseGet process_data h has);
    local line=$(parseGet process_data l line);
    local kill=$(parseGet process_data k kill);
    local help=$(parseGet process_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t--info,_,k,kill \t (string) \t grep process based on info given\n'
    helpmsg+='\t-s,--cpu \t () \t\t sort process by cpu and mem\n'
    helpmsg+='\t-S,--mem \t () \t\t sort process by mem and cpu \n'
    helpmsg+='\t-p,--parent \t (int) \t\t find parent process until reach 1 \n'
    helpmsg+='\t-h,--has \t (string) \t\t check if process exist \n'
    helpmsg+='\t-k,--kill \t (string/uid) \t pkill process via name or uid \n'
    helpmsg+='\t-l,--line \t (int) \t\t sort process line to output, default to 10 \n'

    if ! $(hasValueq "$line"); then line=10; fi;

    info_process() {
        local info="$@"
        if ! $(hasValueq "$info"); then ps aux;
        else ps aux | grep $info; fi;
    }

    sortcpu_process() {
        ps aux | head -n 1 && ps aux | awk 'NR>1 {print $0, $11}' | sort -k 3nr,3 -k 4nr,4 | head -n $line   
    }
    
    sortmem_process() {
        ps aux | head -n 1 && ps aux | awk 'NR>1 {print $0, $11}' | sort -k 4nr,4 -k 3nr,3 | head -n $line   
    }

    parent_process() {
        local PID=$1
        if ! $(hasValueq "$PID"); then return $(_ERC "PID undefined"); fi;
        
        while [ $PID != "1" ] 
        do
            if ! ps -p $PID > /dev/null; then return $(_ERC "PID not found: $PID"); fi;
            echo "---PARENT---"
            ps u -p $PID
            PID=$(ps -o ppid= -p "$PID")
        done
    }

    has_process() {
        local name=$@;
        result=$(pgrep "$name")

        if $(hasValueq $result); then
            return $(_RC 0 "{$name} has pid {$result}")
        else
            return $(_ERC "does not exist")
        fi;
    }

    kill_process() {
        local name=$@;
        if $(string -n $name); then 
            pid $name
            _ED killing pid $name;
            kill $name 
        else 
            if $(os mac); then pkill $name; else pkill -e $name; fi; 
        fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$sortCPU"); then sortcpu_process $sortcpu_process;
    elif $(hasValueq "$sortMEM"); then sortmem_process $sortMEM; 
    elif $(hasValueq "$parent"); then parent_process $parent;
    elif $(hasValueq "$hasit"); then has_process $hasit;
    elif $(hasValueq "$kill"); then kill_process $grepInfo;
    else info_process $grepInfo; 
    fi;
}

docker() {
    declare -A docker_data; parseArg docker_data $@;
    local build=$(parseGet docker_data b build);
    local image=$(parseGet docker_data i image);
    local hasImg=$(parseGet docker_data I hasImg);
    local volume=$(parseGet docker_data v volume);
    local processes=$(parseGet docker_data p process);
    local stop=$(parseGet docker_data s stop);
    local test=$(parseGet docker_data E T test);
    local execs=$(parseGet docker_data e exec);
    local execTest=$(parseGet docker_data stoptest);
    local log=$(parseGet docker_data l log);
    local livelog=$(parseGet docker_data L live);
    local tars=$(parseGet docker_data t tar save);
    local downs=$(parseGet docker_data d download);
    local clean=$(parseGet docker_data c clean);
    local pids=$(parseGet docker_data P pid);
    local kills=$(parseGet docker_data k kill);
    local help=$(parseGet docker_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-b,--build \t (string) \t enter name:tag to build\n'
    helpmsg+='\t-i,--image \t (string?) \t list image or enter image name to view details\n'
    helpmsg+='\t-I,--hasImg \t (string) \t check if image exist\n'
    helpmsg+='\t-v,--volume \t (string?) \t list all or enter name to view volume details\n'
    helpmsg+='\t-p,--process \t (string?) \t list all or enter name to view process details\n'
    helpmsg+='\t-s,--stop \t (string) \t enter name to stop and remove container\n'
    helpmsg+='\t-E,-T,--test \t (string) \t enter image name to test with bash\n'
    helpmsg+='\t-e,--exec \t (string) \t enter name to exec with bash\n'
    helpmsg+='\t-stoptest \t (string) \t enter name to pause and test container, then unpause\n'
    helpmsg+='\t-l,--log \t (string) \t enter name to log details\n'
    helpmsg+='\t-L,--live \t (string) \t enter name to view log live\n'
    helpmsg+='\t-t,--tar,--save \t (string) \t enter x.tar to load, enter container name to export x.tar\n'
    helpmsg+='\t-d,--download \t (string) \t download offline and import file by using [name:tag] \n'
    helpmsg+='\t-c,--clean \t (string) \t clean docker volume\n'
    helpmsg+='\t-P,--pid \t (int) \t\t enter pid of process to find target docker container\n'
    helpmsg+='\t-k,--kill \t (int) \t\t enter name or id to kill process and stop container\n'
    
    unset -f docker;
    DOCKER=$(which docker);
    
    _find_name() {
        local target; 
        if $(hasValueq $@); then target="$($DOCKER ps -a --format '{{.Names}}' | grep $@)";
        else target="$($DOCKER ps -a --format '{{.Names}}')"; fi;

        if ! $(hasValueq $target); then return $(_ERC "target -$@- not found"); 
        elif ! $(trimArgs "$target" | grep -q " "); then _EC "$target";
        else promptSelect "select target docker container:" $target; fi
    }

    _find_img() {
        local target; 
        if $(hasValueq $@); then target="$($DOCKER images --format '{{.Repository}}:{{.Tag}}' | grep $@)";
        else target="$($DOCKER images --format '{{.Repository}}:{{.Tag}}')"; fi;

        if ! $(hasValueq $target); then return $(_ERC "target -$@- not found"); 
        elif ! $(trimArgs "$target" | grep -q " "); then _EC "$target";
        else promptSelect "select target docker image:" $target; fi

    }

    _find_id() {
        local target; 
        if $(hasValueq $@); then target=$($DOCKER ps -a | grep $@);
        else target=$($DOCKER ps -a); fi;
        IFS=$'\n' read -r -d '' -a containers <<< "$target"

        if ! $(hasValueq $containers); then return $(_ERC "target -$@- not found"); 
        elif [ ${#containers[@]} -eq 1 ]; then _EC $(echo ${containers[0]} | awk '{print $1}')
        else 
            choice=$(_promptArray "select target docker container:" containers);
            _EC $(echo $choice | awk '{print $1}')
        fi
    }

    build_docker() {
        local nameTag=$@
        if ! $(hasValue $nameTag); then return $(_ERC "name:tag undefined"); fi;
        $DOCKER build --progress=plain -t $nameTag .
    }

    image_docker() {
        local imageName="$@"
        if ! $(hasValueq $imageName); then $DOCKER image ls;
        else imageName="$(_find_img $@)";
        $DOCKER inspect $imageName; fi;
    }

    imageHas_docker() {
        local imageName=$($DOCKER image ls --format "{{.Repository}}:{{.Tag}} {{.ID}}"| grep $@)
        if $(hasValue $imageName); then return $(_RC 0 "{$@} found");
        else return $(_ERC $@ image not found); fi;
    }

    volume_docker() {
        local name
        if $(hasValueq $@); then name="$(_find_name $@)" || name="$(_find_id $@)"; fi;
        $DOCKER inspect --format='{{.Name}}: {{range .Mounts}}{{println " - " .Name ":" .Source " -> " .Destination }}{{end}}' $($DOCKER ps -q) | grep "$name"
    }

    process_docker() {
        local name="$@"
        if $(hasValueq $@); then name="$(_find_name $@)" || name="$(_find_id $@)"; fi;
        if ! $(hasValueq $name); then $DOCKER ps -a;
        else $DOCKER ps -a | grep $name; fi;
    }

    stop_docker() {
        local name
        if $(hasValueq $@); then name="$(_find_name $@)" || name="$(_find_id $@)"; fi;
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER stop $name && $DOCKER rm $name;
    }

    test_docker() {
        local name="$(_find_img $@)";
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER run --rm -it --entrypoint sh $name -c '[ -x /bin/bash ] && exec /bin/bash || [ -x /bin/ash ] && exec /bin/ash || exec /bin/sh'
    }

    exec_docker() {
        local name="$(_find_name $@)" || name="$(_find_id $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER exec -it --privileged --entrypoint sh $name -c '[ -x /bin/bash ] && exec /bin/bash || [ -x /bin/ash ] && exec /bin/ash || exec /bin/sh'
    }

    execTest_docker() {
        local name="$(_find_name $@)" || name="$(_find_id $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER pause $name
        $DOCKER exec -it --privileged --entrypoint sh $name -c '[ -x /bin/bash ] && exec /bin/bash || [ -x /bin/ash ] && exec /bin/ash || exec /bin/sh'
        $DOCKER unpause $name
    }

    log_docker() {
        local name="$(_find_name $@)" || name="$(_find_id $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER logs $name | tail -n 500
    }

    livelog_docker() {
        local name="$(_find_name $@)" || name="$(_find_id $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER logs -f --tail 500 $name
    }

    tar_docker() {
        local name="$@";
        if $(echo "$name" | grep -q ".tar"); then
            _ED docker loading $name
            $DOCKER load < $name
        else 
            dname="$(_find_img $@)"
            if ! $(hasValueq $dname); then 
                dname="$(_find_name $@)"
            fi;

            if ! $(hasValueq $dname); then
                dname="$(_find_img $@)"
            fi;

            if ! $(hasValueq $dname); then 
                return $(_ERC "name {$name} not found")
            fi;

            d2name=$dname;
            if $(string -c "$dname" "/"); then d2name="$(echo $dname | sed 's/\//-/g; s/:/-V-/g')-SDC"; fi;
            _ED docker exporting $d2name from $dname
            $DOCKER save -o $d2name.tar $dname
        fi;
    }

    down_docker() {
        local name="$@";
        if ! $(has -f ~/.application/DDO.sh); then
            _ED downloading docker_download_offline.sh
            download https://hub.gitmirror.com/https://raw.githubusercontent.com/moby/moby/master/contrib/download-frozen-image-v2.sh ~/.application/DDO.sh
            chmod 777 ~/.application/DDO.sh 
        fi;
      
        dirName=$(password)
        _ED downloading $name to ~/.application/$dirName
        mkdir ~/.application/$dirName
        ~/.application/DDO.sh ~/.application/$dirName $name
        if [ $? -ne 0 ]; then rm -rf ~/.application/$dirName && return $(_ERC "download failed"); fi; 

        _ED importing $name to docker
        tar -cC ~/.application/$dirName . | docker load && rm -rf ~/.application/$dirName

        _ED importing complete
    }

    clean_docker() {
        $DOCKER system prune --volumes
    }

    pid_docker() {
        local PID=$@
        containerID=$(grep -oP 'docker-\K[0-9a-f]+(?=\.scope)' /proc/$PID/cgroup)
        if ! $(hasValueq $containerID); then return $(_ERC "Docker pid -$PID- not found"); fi;
        containerName=$($DOCKER ps --filter "id=$containerID" --format "{{.Names}}")
        _ED containerName: $containerName
        $DOCKER ps -a | grep $containerName
    }

    kill_docker() {
        local name="$(_find_id $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        local PID=$(ps aux | grep -E moby.*\ $name | grep -v grep | awk '{print $2}');
        if ! $(hasValueq $PID); then return $(_ERC "process pid not found"); fi;
        local pspid=$(ps aux | grep $PID);
        boolNum=$(prompt "kill target process: $pspid");
        if [ "$boolNum" -eq 1 ]; then 
            _ED killing pid $PID
            kill -9 $PID
            _ED stoping container $name
            $DOCKER stop $name && $DOCKER rm $name; 
        fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$build"); then build_docker $build;
    elif $(hasValueq "$image"); then image_docker $image;
    elif $(hasValueq "$hasImg"); then imageHas_docker $hasImg;
    elif $(hasValueq "$volume"); then volume_docker $volume;
    elif $(hasValueq "$processes"); then process_docker $processes;
    elif $(hasValueq "$stop"); then stop_docker $stop;
    elif $(hasValueq "$test"); then test_docker $test;
    elif $(hasValueq "$execs"); then exec_docker $execs;
    elif $(hasValueq "$execTest"); then execTest_docker $execTest;
    elif $(hasValueq "$log"); then log_docker $log;
    elif $(hasValueq "$livelog"); then livelog_docker $livelog;
    elif $(hasValueq "$tars"); then tar_docker $tars;
    elif $(hasValueq "$downs"); then down_docker $downs;
    elif $(hasValueq "$clean"); then clean_docker $clean;
    elif $(hasValueq "$pids"); then pid_docker $pids; 
    elif $(hasValueq "$kills"); then kill_docker $kills; 
    fi;
}

dc() { 
    declare -A dc_data; parseArg dc_data $@;
    local up=$(parseGet dc_data u up);
    local down=$(parseGet dc_data d down);
    local down1=$(parseGet dc_data D d1 down1);
    local stop=$(parseGet dc_data s stop rm remove);
    local image=$(parseGet dc_data i image);
    local build=$(parseGet dc_data b build);
    local rebuild=$(parseGet dc_data B rebuild);
    local processes=$(parseGet dc_data p process);
    local execs=$(parseGet dc_data e exec);
    local execline=$(parseGet dc_data E execline);
    local restart=$(parseGet dc_data r restart);
    local restart1=$(parseGet dc_data R r1 restart1);
    local log=$(parseGet dc_data l log);
    local livelog=$(parseGet dc_data L live);
    local help=$(parseGet dc_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--up \t () \t\t start with docker compose\n'
    helpmsg+='\t-d,--down \t () \t\t down containers \n'
    helpmsg+='\t-D,-d1,--down1 \t () \t\t down 1 container \n'
    helpmsg+='\t-s,--stop,--rm,--remove \t () \t\t remove containers with volumes \n'
    helpmsg+='\t-i,--image \t () \t\t show container images \n'
    helpmsg+='\t-p,--process \t () \t\t show container process \n'
    helpmsg+='\t-b,--build \t () \t\t build dockerfile \n'
    helpmsg+='\t-B,--rebuild \t () \t\t rebuild dockerfile with no cache \n'
    helpmsg+='\t-e,--exec \t () \t\t exec container with bash or sh \n'
    helpmsg+='\t-E,--execline \t (name,cmd) \t exec cmd on name \n'
    helpmsg+='\t-r,--restart \t () \t\t restart all containers \n'
    helpmsg+='\t-R,--r1,--restart1 \t () \t\t restart 1 container \n'
    helpmsg+='\t-l,--log \t () \t\t log target containers \n'
    helpmsg+='\t-L,--live \t () \t\t live log target containers \n'

    unset -f docker;
    DOCKER=$(which docker);
    
    _find_name() {
        local target;
        if $(hasValueq $@); then target="$($DOCKER compose ps --format '{{.Service}}\t{{.Name}}\t{{.Image}}' 2>/dev/null | grep $@ | awk '{print $1}')"; 
        else target="$($DOCKER compose ps --format '{{.Service}}\t{{.Name}}\t{{.Image}}' 2>/dev/null | awk '{print $1}')"; fi;

        if ! $(hasValueq $target); then return $(_ERC "target -$@- not found"); 
        elif ! $(trimArgs "$target" | grep -q " "); then _EC "$target";
        else promptSelect "select target docker compose container:" $target; fi
    }

    up_dc() {
        if ! $(hasFile .env); then touch .env; fi;
        $DOCKER compose --env-file .env up -d
    }

    down_dc() {
        $DOCKER compose down --remove-orphans
    }

    down1_dc() {
        local name="$(_find_name $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER compose down $name
    }

    stop_dc() {
        $DOCKER compose rm -s
    }

    image_dc() {
        $DOCKER compose images
    }

    restart_dc() {
        $DOCKER compose restart
    }

    restart1_dc() {
        local name="$(_find_name $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER compose restart $name
    }

    process_dc() {
        $DOCKER compose ps -a
    }

    build_dc() {
        $DOCKER compose build --progress=plain
    }

    rebuild_dc() {
        $DOCKER compose build --no-cache --progress=plain
    }

    exec_dc() {
        local name="$(_find_name $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER compose exec -it --privileged $name sh -c '[ -x /bin/bash ] && exec /bin/bash || [ -x /bin/ash ] && exec /bin/ash || exec /bin/sh'
    }

    exec_line_dc() {
        local target=$1 cmds="${@:2}"
        $DOCKER compose exec --privileged $target $cmds
    }

    log_dc() {
        local name="$(_find_name $@)" 
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER compose logs $name | tail -n 500
    }

    livelog_dc() {
        local name="$(_find_name $@)"
        if ! $(hasValueq $name); then return $(_ERC "name not found"); fi;
        $DOCKER compose logs -f --tail 500 $name
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; fi;
    if ! $(hasFile "docker-compose.yml"); then return $(_ERC "docker-compose.yml not present in the current dir"); 
    elif $(hasValueq "$up"); then up_dc $up;
    elif $(hasValueq "$down"); then down_dc $down;
    elif $(hasValueq "$down1"); then down1_dc $down1;
    elif $(hasValueq "$stop"); then stop_dc $stop;
    elif $(hasValueq "$image"); then image_dc $image;
    elif $(hasValueq "$build"); then build_dc $build;
    elif $(hasValueq "$rebuild"); then rebuild_dc $rebuild;
    elif $(hasValueq "$processes"); then process_dc $processes;
    elif $(hasValueq "$execs"); then exec_dc $execs;
    elif $(hasValueq "$execline"); then exec_line_dc "$execline";
    elif $(hasValueq "$restart"); then restart_dc $restart;
    elif $(hasValueq "$restart1"); then restart1_dc $restart1;
    elif $(hasValueq "$log"); then log_dc $log;
    elif $(hasValueq "$livelog"); then livelog_dc $livelog; 
    fi;
}

zip() {
    declare -A zip_data; parseArg zip_data $@;
    local target=$(parseGet zip_data t target _);
    local dest=$(parseGet zip_data d dest);
    local show=$(parseGet zip_data s show l ls);
    local tozip=$(parseGet zip_data z zip);
    local ext=$(parseGet zip_data e ext);
    local unzip=$(parseGet zip_data u unzip);
    local help=$(parseGet zip_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-t,--target,_ \t\t (string) \t target to perform smort operation\n'
    helpmsg+='\t-d,--dest \t\t (string) \t when zip, dest loc: default to plaintime.zip; when unzip, dest loc: unzip to target dir \n'
    helpmsg+='\t-s,--show,-l,--ls \t (string) \t show content of zip\n'
    helpmsg+='\t-z,--zip \t\t (strings) \t zip the target files\n'
    helpmsg+='\t-e,--ext \t\t (string) \t extension to zip to, default: zip\n'
    helpmsg+='\t-u,--unzip \t\t (string) \t unzip the target file\n'

    if ! $(hasValueq $ext); then ext="zip"; fi;

    show_zip() {
        local path=$(pathGetFull $@);
        7z l $path
        _ED displayed content of {$path}
    }

    tozip_zip() {
        local targets="$@"
        if ! $(hasValueq $dest); then dest="$(dates -P).$ext"; fi;
        7z a $dest $targets
        _ED zip folders {$targets} to dest {$dest}
    }

    unzip_zip() {
        local targets="$@"
        if ! $(hasValueq $dest); then dest="$(trimArgs ${targets%.*})_unzip"; fi;
        7z x $targets -o$dest
        _ED unzip {$targets} to dest { $dest }
    }

    smort_zip() {
        local targets="$@"
        if ! $(hasValueq "$target"); then return $(_ERC "missing args"); fi;

        local count=0
        for item in $targets; do count=$((count + 1)); done;

        if [ "$count" -eq 1 ] && $(_ENULL 7z t "$targets"); then unzip_zip "$targets";
        else tozip_zip "$targets"; fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$show"); then show_zip $show; 
    elif $(hasValueq "$tozip"); then tozip_zip "$tozip"; 
    elif $(hasValueq "$unzip"); then unzip_zip "$unzip";  
    else smort_zip "$target"; 
    fi;
}

syscheck() {
    declare -A syscheck_data; parseArg syscheck_data $@;
    local check=$(parseGet syscheck_data c check _);
    local large=$(parseGet syscheck_data l large);
    local help=$(parseGet syscheck_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--check,_ \t () \t\t check current system status, threshold=90\n'
    helpmsg+='\t-l,--large \t (string, int) \t large file finder, define [ path=".", length=20 ]\n'

    large_syscheck() {
        local largeDir=$1 largeLength=$2
        if ! $(hasValueq $largeDir); then largeDir="."; fi;
        if ! $(hasValueq $largeLength); then largeLength=20; fi;
        du -ahx $largeDir | sort -rh | head -n $largeLength; 
    }

    check_syscheck() {
        if ! $(string -n $check); then check=90; fi;
        if $(os mac); then

            _ED checking volume +

            while IFS= read -r line; do
            volumePercent=$(echo "$line" | awk '{print $5}' | sed 's/%//');
            volumeName=$(echo "$line" | awk '{print $1}');
            if [ "$volumePercent" -ge "$check" ]; then
                _ERC "Critical alert: $volumeName is at $volumePercent% usage."
                large_syscheck $volumeName; 
            fi; 
            done < <(df -h | grep '^/dev/disk' | grep -v '/System'); 

            _ED checking memory +

            memLine=$(top -l 1 | grep "PhysMem:"); 
            usedMem=$(echo "$memLine" | awk '{print $2}' | sed 's/[^0-9]//g'); 
            unusedMem=$(echo "$memLine" | awk '{print $(NF-1)}' | sed 's/[^0-9]//g'); 
            totalMem=$(echo "$usedMem + $unusedMem" | bc); 
            if [ "$totalMem" -gt 0 ]; then
                memUsage=$(echo "($usedMem * 100) / $totalMem" | bc); 
                if [ "$memUsage" -ge "$check" ]; then
                    _ERC "Critical alert: Memory usage is at ${memUsage}% (Used: ${usedMem}M, Total: ${totalMem}M)."; 
                    process --mem; 
                fi; 
            fi; 

            _ED checking CPU +

            cores=$(sysctl -n hw.ncpu); 
            loadAvg=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $2}'); 
            cpuUsage=$(echo "scale=0; ($loadAvg / $cores) * 100 / 1" | bc); 
            if [ "$cpuUsage" -ge "$check" ]; then
                _ERC "Critical alert: CPU load is at ${cpuUsage}% (Current 5min average: ${loadAvg}, Cores: ${cores})."; 
                process --cpu; 
            fi; 

        elif $(os linux); then

            _ED checking volume +

            while IFS= read -r line; do
                volumePercent=$(echo "$line" | awk '{print $5}' | sed 's/%//');
                volumeName=$(echo "$line" | awk '{print $1}');
                if [ "$volumePercent" -ge "$check" ]; then
                    _ERC "Critical alert: $volumeName is at $volumePercent% usage."
                    large_syscheck $volumeName; 
                fi;
            done < <(df -h | grep '^/dev/' | grep -v '/boot'); 

            _ED checking memory +

            memInfo=$(free | awk '/Mem:/ {print $3, $2}'); 
            usedMem=$(echo "$memInfo" | awk '{print $1}'); 
            totalMem=$(echo "$memInfo" | awk '{print $2}'); 
            memUsage=$(echo "($usedMem * 100) / $totalMem" | bc); 
            if [ "$memUsage" -ge "$check" ]; then
                _ERC "Critical alert: Memory usage is at $memUsage%."; 
                process --mem; 
            fi; 

            _ED checking CPU +

            cores=$(nproc); 
            loadAvg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f2 | tr -d ' '); 
            cpuUsage=$(echo "scale=0; ($loadAvg / $cores) * 100 / 1" | bc); 
            if [ "$cpuUsage" -ge "$check" ]; then
                _ERC "Critical alert: CPU load is at ${cpuUsage}% (Current 5min average: ${loadAvg}, Cores: ${cores})."; 
                process --cpu; 
            fi; 

            _ED checking docker +

            if $(hasCmd docker) && $(docker | grep -q restart); then 
                _ERC "Critical alert: docker container keep restarting"
                docker -p restart; 
            fi;  

        fi; 

    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$large"); then large_syscheck $large; 
    else check_syscheck $check; 
    fi;
}

extra() { 
    declare -A extra_data; parseArg extra_data $@;
    local tree=$(parseGet extra_data tree pstree);
    local clone=$(parseGet extra_data clone);
    local copy=$(parseGet extra_data c copy);
    local strict=$(parseGet extra_data eval strict);
    local current=$(parseGet extra_data cd current currentdir)
    local help=$(parseGet extra_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t--tree,--pstree \t\t () \t\t display pstree\n'
    helpmsg+='\t--clone \t\t\t () \t\t clone u to target dir\n'
    helpmsg+='\t-c,--copy \t\t\t () \t\t copy content to clipboard\n'  
    helpmsg+='\t--strict,--eval \t\t () \t\t bash: to use strict\n'
    helpmsg+='\t--cd,--current,--currentdir \t () \t\t bash: to find current dir\n'  

    tree_extra() {
        if $(os -c mac); then pstree; else ps auxwwf; fi;
    }

    clone_extra() {
        local location=$1; 
        if ! $(hasValueq $location); then location="."; fi; 
        cp $(_SCRIPTPATHFULL) $location; 
    }

    copy_extra() {
        shift
        if $(os -c mac); then _EC $(parse2 "$@") | pbcopy; 
        elif $(os -c win); then _EC "$@" | clip.exe;
        elif $(hasCmd xsel); then _EC "$@" | xsel --clipboard --input; 
        elif $(hasCmd xclip); then _EC "$@" | xclip -selection clipboard; 
        else _ERC "copy content failed"; fi;
    }

    strict_extra() {
        echo 'eval $(u _strict "$@");'
    }

    currentDir_extra() {
        echo 'DIR="$(eval "$(u _PATH)");"'
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$tree"); then tree_extra $tree; 
    elif $(hasValueq "$clone"); then clone_extra $clone; 
    elif $(hasValueq "$copy"); then copy_extra "$@"; 
    elif $(hasValueq "$strict"); then strict_extra $strict; 
    elif $(hasValueq "$current"); then currentDir_extra $current; 
    fi;
}

calc() {
    local equation=$(_EC "$@"); 
    _EC $(echo "scale=8; $equation" | bc | sed -E 's/([0-9]*\.[0-9]*[1-9])0*$/\1/; s/^\.+/0./');
}

mount() {
    declare -A mount_data; parseArg mount_data $@;
    local info=$(parseGet mount_data i info _);
    local mountTo=$(parseGet mount_data m mount);
    local unmounted=$(parseGet mount_data I uminfo);
    local checkDir=$(parseGet mount_data c check);
    local help=$(parseGet mount_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-i,--info,_ \t (string?) \t\t information of target mounting device\n'
    helpmsg+='\t-m,--mount \t (string,string) \t mount (source) devices to (target) folder \n'
    helpmsg+='\t-I,--uminfo \t () \t\t\t find mounted devices \n'
    helpmsg+='\t-c,--check \t (string) \t\t check if dir has mounted info\n'

    unset -f mount;
    MOUNT=$(which mount);

    info_mount() {
        local target="$@"
        _ED finding mount info {$@}
        if $(hasCmd fdisk); then
            fdisk -l $target; 
        fi;
        if $(hasCmd lsblk); then 
            lsblk -f
        fi;
    }

    mount_mount() {
        local source=$1
        local target=$2
        if [[ "$source" != /dev/* ]]; then source="/dev/$source"; fi;

        if ! $(hasValueq $source); then return $(_ERC "source does not exist"); fi;
        if ! $(has -p $source); then return $(_ERC "{$source} does not exist"); fi;
        if ! $(hasValueq $target); then return $(_ERC "target does not exist"); fi;
        
        confirm=$(prompt mounting source {$source} to target {$target} \(N/y?\) )
        if [[ $confirm = 1 ]]; then  
            fsType=$(lsblk -no FSTYPE "$source");
            acceptedTypes=("ext2" "ext3" "ext4" "vfat" "ntfs" "exfat" "xfs" "btrfs");
            if [[ ! " ${acceptedTypes[@]} " =~ " ${fsType} " ]]; then return $(_ERC "source {$source} file type is {$fsType},not accepted, use mkfs.ext4 first"); fi; 
            
            sudo $MOUNT "$source" "$target"; 
            if ! $MOUNT | grep -q "$target"; then return $(_ERC "Failed to mount {$source} at {$target}."); fi;

            confirm=$(prompt writing to fstab \(N/y?\) );
            if [[ $confirm = 1 ]]; then  
                if ! grep -q "$source" /etc/fstab; then return $(_ERC "source {$source} is already in /etc/fstab."); fi;
                echo "$source $target $fsType defaults 0 2" | sudo tee -a /etc/fstab; 
                _ED {"$source $target $fsType defaults 0 2"} added to fstab 
            fi; 
        fi;
    }

    unmounted_mount() {
        _ED finding unmounted info
        if $(hasCmd lsblk); then 
            lsblk --noheadings --raw -o NAME,MOUNTPOINT | awk '$1~/[[:digit:]]/ && $2 == ""'
        fi;
    }

    check_mount() {
        local target="$@"
        if ! $(hasValueq $target); then target="."; fi;
        _ED checking if the dir {$target} is mounted by a source
        if $(hasCmd findmnt); then
            _E2 findmnt $target; 
        fi;
    }

    general_mount(){
        info_mount
        unmounted_mount
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$info"); then info_mount $info;
    elif $(hasValueq "$mountTo"); then mount_mount $mountTo;
    elif $(hasValueq "$unmounted"); then unmounted_mount $unmounted;
    elif $(hasValueq "$checkDir"); then check_mount $checkDir;
    else general_mount; 
    fi;
}

# usage: put 'eval $(u _strict "$@");' at the end of the file
# then the script had to be called with the existing function name 
_strict() {
    echo -e '
    cd "$(dirname "${BASH_SOURCE[0]}")";
    help() { 
        compgen -A function | grep -v "^_";
    };
    _function_exists() {
        declare -f -F $1 > /dev/null;
        return $?;
    };
    _execute_function() {
        local function_name="$1";
        
        if _function_exists "$function_name"; then
            "$@";
        else
            u _ERC "Function {$function_name} not found.";
        fi;
    };
    _execute_function "$@";
    '
}

sf() {
    search $@ -s
}

# -c,--content,_
# -p,--path (bool) search path only
# -b,--base "."
# -s,--show (int) show surrounding lines
# -i,--ignore (string) a;b;c
# -D,--Depth (int)
search() { 
    declare -A search_data; parseArg search_data $@;
    local content=$(parseGet search_data c content _);
    local path=$(parseGet search_data p path n name);
    local base=$(parseGet search_data b base);
    local show=$(parseGet search_data s show);
    local hidden=$(parseGet search_data h hidden);
    local ignore=$(parseGet search_data i ignore);
    local depth=$(parseGet search_data D depth);
    local minute=$(parseGet search_data m minute)
    local help=$(parseGet search_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--content,_ \t\t (string) \t content to search \n'
    helpmsg+='\t-p,--path,-n,--name \t (string) \t search for file or folder name only\n'
    helpmsg+='\t-b,--base \t\t (string) \t base directory to search in, default "."\n'
    helpmsg+='\t-s,--show \t\t (int) \t\t show n(*_2) lines of surrounding context\n'
    helpmsg+='\t-h,--hidden \t\t () \t\t search hidden folder\n'
    helpmsg+='\t-i,--ignore \t\t (string) \t ignore list, use ";" as delimiter \n'
    helpmsg+='\t-D,--depth \t\t (int) \t\t search depth, default 7\n'
    helpmsg+='\t-m,--minute \t\t (int) \t\t search top Y changed file in last X minutes, default [30,20]\n'

    _load_args() {
        AG_ARGS="";

        local preIgnoreList="$ignore;node_modules;.git;package-lock.json;"
        IFS=';' read -ra elements <<< "$preIgnoreList"
        
        for element in "${elements[@]}"; do
            element="${element#"${element%%[![:space:]]*}"}"
            element="${element%"${element##*[![:space:]]}"}"
            if $(hasValueq $element); then AG_ARGS="$AG_ARGS --ignore $element"; fi; 
        done; 

        if ! $(hasValueq $depth); then depth=7; fi;
        AG_ARGS="$AG_ARGS --depth $depth"; 
 
        if ! $(hasValueq "$show"); then AG_ARGS="$AG_ARGS --files-with-matches";
        else AG_ARGS="$AG_ARGS --context $show"; fi;

        if $(hasValueq $hidden); then AG_ARGS="$AG_ARGS --hidden"; fi;
        AG_ARGS="$AG_ARGS --follow --noheading --column"; 
    }

    content_search() {
        _load_args
        contentString=$(echo "$@" | xargs)
        eval $(_EC ag $AG_ARGS "\"$contentString\"" $base)
    }

    path_search() {
        _load_args
        contentString=$(echo "$@" | xargs)
        eval $(_EC ag $AG_ARGS -g "\"$contentString\"" $base)
    }

    minute_search() {
        if ! $(hasValueq $base); then base="."; fi;
        local results=();
        local sequence=$(echo $@ | xargs);
        minute=$(echo $sequence | awk '{print $1}');
        tops=$(echo $sequence | awk '{print $2}');
        if ! $(hasValueq $minute); then minute="30"; fi;
        if ! $(hasValueq $tops); then tops="20"; fi; 

        _ED searching base {$base} top {$tops} minute {$minute}

        if $(os mac); then 
            while IFS= read -r line; do 
                results+=("$line");
            done < <(find $base -type f -mmin -$minute -not -path "*/node_modules/*" -not -path "*/.git/*" -exec stat -f '%m %N' {} \; | sort -n -r | head -n $tops); 
        else 
            while IFS= read -r line; do 
                results+=("$line");
            done < <(find $base -type f -mmin -$minute -not -path "*/node_modules/*" -not -path "*/.git/*" -exec stat -c '%Y %n' {} \; | sort -n -r | head -n $tops); 
        fi;

        for entry in "${results[@]}"; do
            timestamp=$(echo "$entry" | awk '{print $1}');
            name=$(echo "$entry" | awk '{$1=""; print $0}' | sed 's/^ //');
            formated=$(dates -q $timestamp);
            echo "$formated - $name";
        done
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq $path); then path_search "$path";
    elif $(hasValueq "$minute"); then minute_search "$minute"; 
    else content_search "$content"; 
    fi;
}


# --- EXTRA END ---

# put this at the end of the file
# dispatch for function:
# string -c / --contain
# dates -o /--older
case "$1" in 
    string)
        case "$2" in 
            "-c" | "--contain")
                string -c "${@:3}"
            ;;
            *)
                $@
            ;;
        esac
    ;;
    dates)
        case "$2" in 
            "-o" | "--older")
                dates -o "${@:3}"
            ;;
            *)
                $@
            ;;
        esac
    ;;
    pathGetFull)
        pathGetFull "${@:2}"
    ;;
    prompt)
        prompt "${@:2}"
    ;;
    promptString)
        promptString "${@:2}"
    ;;
    promptSelect)
        promptSelect "${@:2}"
    ;;
    zip)
        zip "${@:2}"
    ;;
    *)
        $@
esac
