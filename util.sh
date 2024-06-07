#!/usr/bin/env bash

# Author: Awada.Z

# (): string
version() {
    echo 5.10.4
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

# (declare -A Option, ...data): {key:value, _:"" } 
# example: declare -A data; parseArg data $@; parseGet data _;
parseArg() {
    local -n parse_result=$1;
    local _target="_"
    for i in ${@:2:$#}; do    
        if ! [[ "$i" =~ ^"-" ]]; then parse_result[$_target]="${parse_result[$_target]}$i ";
        else _target=$(echo " $i" | sed 's/^ -*//'); [[ -z "${parse_result[$_target]}" ]] && parse_result[$_target]=' ';
        fi;
    done;
}

# (declare -A Option, ...keys): string
parseGet() {
    local -n parse_get=$1;
    for i in ${@:2:$#}; do if ! [[ -z ${parse_get[$i]} ]]; then _EC "${parse_get[$i]}" && return $(_RC 0 $@); fi; done;
    return 1;
}

pathGetFull() {
    local path=$(cd "$(dirname "$1")" || exit; pwd)
    local file=$(basename "$1")

    if [ "$file" = ".." ]; then
        _EC "$(dirname "$path")"
    else
        _EC  "$path/$file"
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

# just read input
promptString() {
    local prompter="$@"
    read -p "$prompter"$'\n' responseString
    echo $responseString
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
    if ! [[ -z "$(command -v $1)" ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
}

# (cmdName): bool
hasCmdq() {
    [[ ! -z "$(command -v "$1")" ]];
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

# -v,--value; -V,--Value, *_default slient
# -c,--cmd,--command; -C,--Cmd,--Command silent
# -d,--dir; -D,--Dir silent
# -f,--file; -F,--File silent
# -e,--env; -E,--Env silent
has() {
    declare -A has_data; parseArg has_data $@;

    if [ "$_target" = "_" ]; then 
        return $(! [[ -z $1 ]]);
    fi;

    parseGetQ() {
        local -n parse_get=$1;
        for i in ${@:2:$#}; do if ! [[ -z ${parse_get[$i]} ]]; then echo "${parse_get[$i]}" && return 0; fi; done;
        return 1;
    }

    local value=$(parseGet has_data v value);
    local valueQ=$(parseGetQ has_data V Value);
    local cmd=$(parseGet has_data c cmd command);
    local cmdQ=$(parseGetQ has_data C Cmd Command);
    local dir=$(parseGet has_data d dir);
    local dirQ=$(parseGetQ has_data D Dir);
    local file=$(parseGet has_data f file);
    local fileQ=$(parseGetQ has_data F File);
    local env=$(parseGet has_data e env);
    local envQ=$(parseGetQ has_data E Env);
    local help=$(parseGet has_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-v,--value \t (string) \t check if it has value\n'
    helpmsg+='\t-V,--Value,*_ \t (string) \t check if it has value quietly. Can do $(has "$value")\n'
    helpmsg+='\t-c,--cmd \t (string) \t check if it has command\n'
    helpmsg+='\t-C,--Cmd \t (string) \t check if it has command quietly\n'
    helpmsg+='\t-d,--dir \t (string) \t check if it has directory\n'
    helpmsg+='\t-D,--Dir \t (string) \t check if it has directory quietly\n'
    helpmsg+='\t-f,--file \t (string) \t check if it has file\n'
    helpmsg+='\t-F,--File \t (string) \t check if it has file quietly\n'
    helpmsg+='\t-e,--env \t (string) \t check if it has environment\n'
    helpmsg+='\t-E,--Env \t (string) \t check if it has environment quietly\n'

    value_has() {
        if ! [[ -z $1 ]]; then return $(_RC 0 "$@"); else return $(_RC 1 "$@"); fi;
    }

    value_Q_has() {
        ! [[ -z $1 ]];
    }

    cmd_has() {
        if ! [[ -z "$(command -v $1)" ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    cmd_Q_has() {
        ! [[ -z "$(command -v "$1")" ]];
    }

    dir_has() {
        if [ -d "$1" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    dir_Q_has() {
        [ -d "$1" ];
    }

    file_has() {
        if [ -f "$1" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    file_Q_has() {
        [ -f "$1" ];
    }

    env_has() {
        if ! [[ -z ${!1+set} ]]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    env_Q_has() {
        ! [[ -z ${!1+set} ]]; 
    }

    if $(value_Q_has "$help"); then printf "$helpmsg"; 
    elif [ "$_target" == 'v' ] || [ "$_target" == 'value' ]; then value_has "$value"; 
    elif [ "$_target" == 'V' ] || [ "$_target" == 'Value' ]; then value_Q_has "$valueQ"; 
    elif $(value_Q_has "$cmd"); then cmd_has $cmd; 
    elif $(value_Q_has "$cmdQ"); then cmd_Q_has $cmdQ; 
    elif $(value_Q_has "$dir"); then dir_has $dir; 
    elif $(value_Q_has "$dirQ"); then dir_Q_has $dirQ; 
    elif $(value_Q_has "$file"); then file_has $file; 
    elif $(value_Q_has "$fileQ"); then file_Q_has $fileQ; 
    elif $(value_Q_has "$env"); then env_has $env; 
    elif $(value_Q_has "$envQ"); then env_Q_has $envQ; 
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
stats() {
    declare -A stats_data; parseArg stats_data $@;
    local size=$(parseGet stats_data s size _);
    local modify=$(parseGet stats_data m modify);
    local modifyQ=$(parseGet stats_data M modifyQ)
    local full=$(parseGet stats_data f full);
    local help=$(parseGet stats_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-s,--size,_ \t (string) \t size of the path\n'
    helpmsg+='\t-m,--modify \t (string) \t modify date of the path\n'
    helpmsg+='\t-M,--modifyQ \t (string) \t modify date of the path as long, quiet\n'
    helpmsg+='\t-f,--full \t (string) \t full stats info\n'

    size_stats() {
        _EC $(du -sh $1 | cut -f1)
    }

    modify_stats() {
        if $(os -c mac); then _EC $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" $1); 
        else _EC $(stat --printf="%y\n" $1 | awk -F'[ .]' '{print $1, $2}'); fi;
    }

    modifyQ_stats() {
         # os -c mac quiet
        if $(hasCmdq uname && uname | grep -q Darwin); then
            stat -f "%Sm" -t "%s" $1
        else
            formatDate=$(stat --printf="%y\n" "$1" | awk -F'[ .]' '{print $1, $2}')
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
    local help=$(parseGet os_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--check,_ \t\t (string) \t check os trait fit current os\n'
    helpmsg+='\t-p,--pkgmanager \t () \t\t get current package manager\n'
    helpmsg+='\t-i,--info \t\t () \t\t get os info, including hardware\n'
    helpmsg+='\t-s,--sys \t\t () \t\t get system info, with cpu, mem and disk info\n'

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

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$check"); then check_os $check; 
    elif $(hasValueq "$pkgmanager"); then pkgManager_os $pkgmanager; 
    elif $(hasValueq "$sysinfo"); then sys_os $sysinfo;
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

# -D,--Datetime *_default date+time
# -l,--long long date
# -d,--date date only
# -t,--time time only
# -p,--plain plain format as 2000_12_31_23_59_59
# -i,--iso iso8601 format
# -f,--full full display of dates
# -r,--reparse reparse the date format back
# -o,--older current time minus $2 in sec > $1 time
# -s,--second older than seconds
dates() {
    declare -A date_data; parseArg date_data $@;
    local dateTime=$(parseGet date_data D Datetime _);
    local dateLong=$(parseGet date_data l long);
    local dateOnly=$(parseGet date_data d date);
    local timeOnly=$(parseGet date_data t time);
    local plain=$(parseGet date_data p plain);
    local iso=$(parseGet date_data i iso);
    local full=$(parseGet date_data f full)
    local reparse=$(parseGet date_data r reparse);
    local older=$(parseGet date_data o older);
    local second=$(parseGet date_data s second);
    local help=$(parseGet date_data help);

    local dateFormat='%Y-%m-%d'
    local timeFormat='%H:%M:%S'
    local dateTimeFormat='%Y-%m-%d %H:%M:%S'
    local dateLongFormat='%s'
    local plainFormat='%Y_%m_%d_%H_%M_%S'
    local iso8601="%Y-%m-%dT%H:%M:%S%z"

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-D,--Datetime,_ \t () \t\t date as datetime format\n'
    helpmsg+='\t-l,--long \t\t () \t\t date as long format\n'
    helpmsg+='\t-d,--date \t\t () \t\t date only format of date\n'
    helpmsg+='\t-t,--time \t\t () \t\t time only format of date\n'
    helpmsg+='\t-p,--plain \t\t () \t\t plain format of date\n'
    helpmsg+='\t-f,--full \t\t () \t\t full display format of date\n'
    helpmsg+='\t-r,--reparse \t\t (string) \t reparse string into date\n'
    helpmsg+='\t-o,--older \t\t (string) \t current time minus (-s in sec) > $1 time\n'
    helpmsg+='\t-s,--second \t\t (number) \t older than x second\n'

    toFormat_dates() {
        echo $(date +"$1")
    }

    parseDateOS() {
        timeString=$(echo $1 | xargs)
        format=$2
        additional=$3

        # os -c mac quiet
        if $(hasCmdq uname && uname | grep -q Darwin); then
            echo $(date -j -f "$format" "$timeString" $additional)
        else
            echo $(date -d "$timeString" +"$format" $additional)
        fi;
    }

    reparse_dates() {
        local input=$1
        input=$(trimArgs $1)
        additional=$2

        p0="^[0-9]+$"
        p1="[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+:[0-9]+"
        p2="[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+"
        p3="[0-9]+-[0-9]+-[0-9]+T"
        p4="[0-9]+-[0-9]+-[0-9]+"
        p5="[0-9]+:[0-9]+:[0-9]+"
        target=""

        if [[ $input =~ $p0 ]]; then target=$dateLongFormat; 
        elif [[ $input =~ $p1 ]]; then target=$dateTimeFormat; 
        elif [[ $input =~ $p2 ]]; then target=$plainFormat; 
        elif [[ $input =~ $p3 ]]; then target=$iso8601; 
        elif [[ $input =~ $p4 ]]; then target=$dateFormat; 
        elif [[ $input =~ $p5 ]]; then target=$timeFormat; 
        fi;

        if ! $(hasValueq $target); then return $(_ERC "Error: no pattern found"); 
        else _ED datetime format found, using $target; fi;

        parseDateOS "$input" "$target" $additional
    }

    older_dates() {
        if ! $(hasValueq $second); then return $(_ERC '$second value undefined'); fi;
        
        inputDate=$(echo $@ | xargs)
        target=$(reparse_dates "$inputDate" "+%s")
        current_timestamp=$(date +%s)
        difference=$((current_timestamp - target))

        if [ "$difference" -gt $second ]; then _RC 0 difference:$difference '>' $second;
        else _RC 1 difference:$difference '<' $second; fi;
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
    elif $(hasValueq "$older"); then older_dates $older; 
    elif $(hasValueq "$full"); then full_dates $full; 
    elif $(hasValueq "$reparse"); then reparse_dates "$reparse"; 
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
    local clean=$(parseGet trash_data c clean);
    local delete=$(parseGet trash_data d delete);
    local purge=$(parseGet trash_data P purge);
    local help=$(parseGet trash_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--path,_ \t (string) \t move target path to trash path\n'
    helpmsg+='\t-l,--list \t (string) \t list infos on current input path, default to list all\n'
    helpmsg+='\t-i,--index \t (number) \t input index number and get target trash dir\n'
    helpmsg+='\t-r,--restore \t (string) \t restore folder depends on current path\n'
    helpmsg+='\t-c,--clean \t (number) \t clean trash older than 3 month, default 7890000 \n'
    helpmsg+='\t-d,--delete \t () \t choose a trash and delete it \n'
    helpmsg+='\t-P,--purge \t () \t\t remove all trash from trash path\n'

    local TP="$_U2_Storage_Dir_Trash"
    local trashInfoName="_U2_TRASH_INFO"

    put_trash() {
        local input=$1 
        local inputPath=$(pathGetFull $input)
        local uid="$(uuid)"
        local trashDir=$(trimArgs $TP / $uid)
        local size=$(du -sh $inputPath | awk '{print $1}')
        local infoDir=$(trimArgs $trashDir / $trashInfoName)
        mkdir -p $trashDir
        mv -fv $inputPath $trashDir
        printf "uuid=$uid \noriginalDir=$inputPath \ndtime=$(date +'%Y-%m-%d %H:%M:%S')\nsize=$size\n" > $infoDir
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
            if ! $(eval "$evalStr $target"); then
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
            index=${folder_data[${i}_index]}
            uuid=${folder_data[${i}_uuid]}
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
        trashFilter "dtime" 'a(){ if $(dates -o $@ -s'" $seconds); then return 0; else return 1; fi; }; a "
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
                rmTarget=$(trimArgs $TP / $uuid)
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
    elif $(hasValueq "$path"); then put_trash $path; 
    elif $(hasValueq "$list"); then list_trash $list; 
    elif $(hasValueq "$restore"); then restore_trash $restore; 
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

    if [ "$m" = "yum" ]; then eval $(_EC "$prefix yum update -y $@");
    elif [ "$m" = "brew" ]; then eval $(_EC "brew install $@");
    elif [ "$m" = "apt" ]; then eval $(_EC "$prefix DEBIAN_FRONTEND=noninteractive apt-get upgrade -y $@");
    elif [ "$m" = "apk" ]; then eval $(_EC "$prefix apk upgrade $@");
    elif [ "$m" = "pacman" ]; then eval $(_EC "$prefix pacman -Syu --noconfirm $@");
    elif [ "$m" = "dnf" ]; then eval $(_EC "$prefix dnf upgrade -y $@");
    elif [ "$m" = "choco" ]; then eval $(_EC "choco upgrade -y $@");
    elif [ "$m" = "winget" ]; then eval $(_EC "winget upgrade --accept-package-agreements --accept-source-agreements $@");
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

# (length=10, ?useSymbol): string
password() {
    local length=${1:-10} symbol=$2 range='A-Za-z0-9'
    if ! [[ -z ${symbol} ]]; then range=$range.'!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'; fi;
    LC_ALL=C tr -dc $range </dev/urandom | head -c $length ; echo
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
    local help=$(parseGet string_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-e,--equal \t (string,string) \t\t compare two strings\n'
    helpmsg+='\t-c,--contain \t (string,stringOrRegex) \t check if string contains\n'
    helpmsg+='\t-r,--replace \t (string,string,string) \t 1,original string; 2,search string, 3,replacement \n'
    helpmsg+='\t-n,--number \t (string) \t\t check if string is number \n'
    helpmsg+='\t-i,--index \t (...string,int) \t\t treat string as array, get index of it \n'
    
    equal_string(){
        if [ "$1" = "$2" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    contain_string(){
        if [ "$#" -lt 2 ]; then return $(_RC 1 $@); fi;
        if $(echo "$1" | grep -q $2); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
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

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$equal"); then equal_string $equal;
    elif $(hasValueq "$contain"); then contain_string "$contain";
    elif $(hasValueq "$replace"); then replace_string $replace;
    elif $(hasValueq "$number"); then number_string $number;
    elif $(hasValueq "$index"); then index_string $index;
    fi;

}

noproxy() {
    https_proxy="" http_proxy="" HTTPS_PROXY="" HTTP_PROXY="" no_proxy="" NO_PROXY="" $@
}

# (name, directory="."): string[]
# may use regex for the name
searchFile() {
    local base="."
    if $(hasValueq "$2"); then base="$2"; fi;
    find "$base" -name $1
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
# -q,--quiet disable verbose
post() {
    declare -A post_data; parseArg post_data $@;
    local url=$(parseGet post_data u url _);
    local json=$(parseGet post_data j json);
    local string=$(parseGet post_data s string);
    local CURL=$(parseGet post_data C curl);
    local WGET=$(parseGet post_data W wget);
    local quiet=$(parseGet post_data q quiet);
    local help=$(parseGet post_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-j,--json \t (string) \t json data to post\n'
    helpmsg+='\t-s,--string \t (string) \t string data to post\n'
    helpmsg+='\t-C,--curl \t () \t\t use curl\n'
    helpmsg+='\t-W,--wget \t () \t\t use wget\n'
    helpmsg+='\t-q,--quiet \t () \t\t disable verbose\n'

    if [[ -z $quiet ]]; then curlEx=" -v"; wgetEx=" -d"; 
    else curlEx=""; wgetEx=" -q"; fi;

    # (url, data)
    json_post(){
        local url=$1 data=$2
        curlCmd(){
            curl $curlEx -H "Content-Type: application/json" -d "$data" "$url"
        }
        wgetCmd(){
            wget $wgetEx -O- --header "Content-Type: application/json" --post-data "$data" "$url"
        }
        _REQHelper
    }

    # (url, data)
    string_post() {
        local url=$1 data=$2
        curlCmd(){
            curl $curlEx -H "Content-Type: text/plain" -d "$data" "$url"
        }
        wgetCmd(){
            wget $wgetEx -O- --header "Content-Type: text/plain" --post-data "$data" "$url"
        }
        _REQHelper
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$string"); then string_post $url $string;
    elif $(hasValueq "$json"); then json_post $url $json; 
    else json_post $url; 
    fi;
}

# -u,--url,_ *_default
# -r,--run
# -C,--curl use curl
# -W,--wget use wget
# -q,--quiet disable verbose
get() {
    declare -A get_data; parseArg get_data $@;
    local url=$(parseGet get_data u url _);
    local run=$(parseGet get_data r run);
    local CURL=$(parseGet get_data C curl);
    local WGET=$(parseGet get_data W wget);
    local quiet=$(parseGet get_data q quiet);
    local help=$(parseGet get_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-r,--run \t (string) \t run the script from url, can pass extra command, but no "-" allowed\n'
    helpmsg+='\t-C,--curl \t () \t\t use curl\n'
    helpmsg+='\t-W,--wget \t () \t\t use wget\n'
    helpmsg+='\t-q,--quiet \t () \t\t disable verbose\n'

    if [[ -z $quiet ]]; then curlEx=" -v"; wgetEx=" -d"; 
    else curlEx=""; wgetEx=" -q"; fi;

    script_get() {
        local url=$1 exArgs="${@:2}"
        curlCmd(){
            bash <(curl -s $url) $exArgs;
        }
        wgetCmd(){
            bash <(wget -O - $url) $exArgs; 
        }
        _REQHelper
    }

    url_get(){
        local url=$1
        curlCmd(){
            curl $curlEx -X GET $url
        }
        wgetCmd(){
            wget $wgetEx -O- $url
        }
        _REQHelper
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$run"); then script_get $run;
    elif $(hasValueq "$url"); then url_get $url;
    fi;
}

# (url, outputFileName?)
download() {
    local url=$1 filename=$2
    if $(hasCmd wget); then
        if $(hasValue $filename); then wget -d -O $filename $url; else wget -d $url; fi;
    elif $(hasCmd curl); then
        if $(hasValue $filename); then curl $url -v --output $filename; else curl -v -O $url; fi;
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

# -n,--name,_ *_default
# -v,--variable
# -a,--add,--cmd 
# -e,--edit
# -c,--cat,--display,--show
# -r,--remove,--delete
# -l,--list
quick() {
    declare -A quick_data; parseArg quick_data $@;
    local name=$(parseGet quick_data n name _ e edit r remove delete c cat display show);
    local variable=$(parseGet quick_data v variable);
    local add=$(parseGet quick_data a add cmd)
    local edit=$(parseGet quick_data e edit);
    local display=$(parseGet quick_data c cat display show)
    local remove=$(parseGet quick_data r remove delete);
    local list=$(parseGet quick_data l list);
    local help=$(parseGet quick_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t\t (string) \t *_default, + -e,--edit,-r,--remove,--delete name of the quick data\n'
    helpmsg+='\t-v,--variable \t\t\t (string) \t variable or args to use\n'
    helpmsg+='\t-a,--add,--cmd \t\t\t () \t\t add command to name, can use $1 and args in script, and use quick -v to add to script call\n'
    helpmsg+='\t-e,--edit \t\t\t () \t\t edit the target file\n'
    helpmsg+='\t-c,--cat,--display,--show \t () \t\t display the content of file\n'
    helpmsg+='\t-r,--remove,--delete \t\t () \t\t remove the target file\n'
    helpmsg+='\t-l,--list \t\t\t () \t\t list total quick command\n'

    name=$(echo $name | sed 's/ *//')
    targetFile="$_U2_Storage_Dir_Quick/$name"

    edit_quick(){
        if $(hasCmd nano); then nano $targetFile; elif $(hasCmd vi); then vi $targetFile; fi;
    }

    display_quick() {
        cat "$targetFile"
    }

    add_quick() {
        echo "$add" > $targetFile
    }

    run_quick(){
        part1=$(echo $targetFile | cut -d ' ' -f 1 )
        part2=$(echo $targetFile | sed 's/.* *//')
        bash <(cat $part1) $part2 $variable
    }

    remove_quick(){
        if $(hasFile $targetFile); then trash $targetFile; fi;
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$list"); then ls -a $_U2_Storage_Dir_Quick;
    elif ! $(hasValueq "$name"); then return $(_ERC "name not specified"); 
    elif $(hasValueq "$add"); then add_quick;
    elif $(hasValueq "$edit"); then edit_quick;
    elif $(hasValueq "$display"); then display_quick;
    elif $(hasValueq "$remove"); then remove_quick;
    else run_quick; 
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

        printf 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\nexport NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\n\n' >> $HOME/.bash_mine 
        printf 'if [[ ! -z "$u_proxy" ]] && curl --output /dev/null --silent --head "$u_proxy"; then\n export https_proxy=$u_proxy\n export http_proxy=$u_proxy\n export HTTPS_PROXY=$u_proxy\n export HTTP_PROXY=$u_proxy\nfi;\n'  >> $HOME/.bash_mine

        if $(os -c alpine); then profile="/etc/profile"; echo 'source $HOME/.bash_mine' >> $profile; fi;
        if $(os -c mac); then printf 'export BASH_SILENCE_DEPRECATION_WARNING=1\n' >> $HOME/.bash_mine; fi;
    fi;

    mv $(_SCRIPTPATHFULL) $_U2_Storage_Dir_Bin/u2
    . $_U2_Storage_Dir_Bin/u2 _ED Current Version: $(version)
}

# setup dependency
# -d,--docker add docker to setup
# -n,--node add node to setup
# -b,--bun add bun to setup
setupEX() {
    declare -A setupex_data; parseArg setupex_data $@;
    local basic=$(parseGet setupex_data B basic _);
    local nodeAdd=$(parseGet setupex_data n node);
    local bunAdd=$(parseGet setupex_data b bun);
    local dockerAdd=$(parseGet setupex_data d docker);
    local help=$(parseGet setupex_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-B,--basic,_ \t () \t basic dependency setup\n'
    helpmsg+='\t-n,--node \t () \t add node to setup\n'
    helpmsg+='\t-b,--bun \t () \t add bun to setup\n'
    helpmsg+='\t-d,--docker \t () \t add docker to setup\n'
  
    install_setupEx() {
        local extraArgs=""
        if $(hasValueq "$nodeAdd"); then extraArgs="$extraArgs node"; fi;
        if $(hasValueq "$bunAdd"); then extraArgs="$extraArgs bun"; fi;
        if $(hasValueq "$dockerAdd"); then extraArgs="$extraArgs docker"; fi;
        _ED extraArgs: "$extraArgs"

        setupURL="https://raw.gitmirror.com/Truth1984/shell-simple/main/setup.sh" 
        get -r $setupURL $extraArgs
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
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

# -n,--name,_ *_default
# -u,--update,--upgrade
# -v,--version
# -h,--help
help(){    
    declare -A help_data; parseArg help_data $@;
    local name=$(parseGet help_data n name _);
    local update=$(parseGet help_data u update upgrade);
    local version=$(parseGet help_data v version);
    local help=$(parseGet help_data h help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t (string) \t grep functions with name\n'
    helpmsg+='\t-u,--update,--upgrade \t () \t\t upgrade current script\n'
    helpmsg+='\t-v,--version \t\t (string) \t display current version\n'
    helpmsg+='\t-h,--help \t\t (string) \t display help message\n'

    update_help() {
        _ED Current Version: $(version)
        local scriptLoc="$_U2_Storage_Dir_Bin/u2"
        local updateUrl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"
        local tmpfile=/tmp/$(password).sh
        if $(hasCmd curl); then curl $updateUrl --output $tmpfile
        elif $(hasCmd wget); then wget -O $tmpfile $updateUrl
        fi;

        chmod 777 $tmpfile && $tmpfile setup
    }

    list_help() {
        if ! [[ -z $1 ]]; then compgen -A function | grep $1; else compgen -A function; fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$name"); then list_help $name;
    elif $(hasValueq "$update"); then $(update_help);
    elif $(hasValueq "$version"); then echo $(version);
    else $(list_help);
    fi;
    
}

# --- EXTRA ---

# (string) as path
open() {
    if $(os mac); then /usr/bin/open $@; elif $(os win); then start $@; else xdg-open $@; fi;
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
    local help=$(parseGet port_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--port,--process,_ \t (string) \t use port number or process name to grep port info\n'
    helpmsg+='\t-d,--docker \t\t (string) \t use port number or process name to grep docker port info\n'
    helpmsg+='\t-i,--info \t\t (int) \t find info with target port number \n'

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
    

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$processPort"); then process_port $processPort;
    elif $(hasValueq "$dockerPort"); then docker_port $dockerPort;
    elif $(hasValueq "$infoPort"); then info_port $infoPort;
    else process_port;
    fi;
}

# -h,--head,_
# -m,--moveLocal (name, commitID)
# -M,--moveCloud (name, commitID)
git() {
    declare -A git_data; parseArg git_data $@;
    local head=$(parseGet git_data h head _);
    local moveLocal=$(parseGet git_data m moveLocal);
    local moveCloud=$(parseGet git_data M moveCloud)
    local help=$(parseGet git_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-h,--head,_ \t (string) \t\t transfer head to target location\n'
    helpmsg+='\t-m,--moveLocal \t (string,string) \t move local branch to target id, require: [ name, commitID ] \n'
    helpmsg+='\t-M,--moveCloud \t (string) \t move cloud Reference to target id, require: [ name, commitID ] \n'

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

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$head"); then head_git $head;
    elif $(hasValueq "$moveLocal"); then moveLocal_git $moveLocal;
    elif $(hasValueq "$moveCloud"); then moveCloud_git $moveCloud;
    fi;

    adog_git
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
    local webMessage=$(parseGet _web_data m message);
    local webRedirect=$(parseGet _web_data r redirect)
    local webDirectory=$(parseGet _web_data d dir);
    local help=$(parseGet _web_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--port,_ \t (int) \t open server port, default port 3000\n'
    helpmsg+='\t-m,--message \t (string) \t message to display \n'
    helpmsg+='\t-r,--redirect \t (string) \t redirect to target URL \n'
    helpmsg+='\t-d,--dir \t (string) \t directory server with bun default "." \n'

    if ! $(hasValue $webPort); then webPort=3000; fi;
    if ! $(hasValue $webMessage); then webMessage="web message"; fi;

    server_web() {
        local webcmd=""
        if $(os mac); then webcmd="nc -l $webPort -k";
        else webcmd="nc -l -p $webPort -k"; fi;

        _ED Starting to open test web on port:$webPort
        echo -e "HTTP/1.1 200 OK\r\n\r\n$webMessage" | $webcmd
    }

    redirect_web() {
        local webcmd="" weblocation=$@
        if $(os mac); then webcmd="nc -l $webPort -k";
        else webcmd="nc -l -p $webPort -k"; fi;

        if ! $(hasValueq $weblocation); then return $(_ERC "web redirect url not defined"); fi;
        
        local reHost=$(echo "$weblocation" | sed -E 's#^(https?://)?([^:/]+).*#\1\2#')
        local rePort=$(echo "$weblocation" | sed -E 's#^.*:([0-9]+)$#\1#')

        if [[ $weblocation != http://* && $weblocation != https://* ]]; then weblocation="http://$weblocation"; fi;
        
        _ED Starting to redirect on port:$webPort to location: $weblocation, as \' nc $reHost $rePort \'
        echo -e "HTTP/1.1 301 Moved Permanently\r\nLocation: $weblocation\r\n\r\n" | $webcmd > >(nc $reHost $rePort)
    }

    directory_web() {
        local servePath=$@
        if ! $(hasValueq $servePath); then servePath="."; fi;

        _ED Starting bun file server on port:$webPort with directory: \'$servePath\'
        bun -e "Bun.serve({port:$webPort, fetch(req){ return new Response(Bun.file(\"$servePath\" + new URL(req.url).pathname))}})"
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$webRedirect"); then redirect_web $webRedirect;
    elif $(hasValueq "$webDirectory"); then directory_web $webDirectory;
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
    local help=$(parseGet network_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-2 \t\t (int) \t\t show iftop network, default show nethogs \n'
  
    display_network() {
        if $(hasCmd nethogs) && ! $(hasValueq "$v2"); then 
            sudo nethogs -C
        elif $(hasCmd iftop); then
            sudo iftop -b -P
        fi
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
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
        else _ED "SKIP, LIMITED" 
        fi; 
    }

    restart_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl stop $serviceName || systemctl start $serviceName;
        elif $(hasCmd rc-service); then rc-service stop $serviceName || rc-service start $serviceName; 
        else _ED "SKIP, LIMITED"
        fi; 
    }

    enable_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl start $serviceName && systemctl enable $serviceName;
        elif $(hasCmd rc-update); then rc-service start $serviceName && rc-update add $serviceName default; 
        else _ED "SKIP, LIMITED"
        fi; 
    }

    disable_service() {
        local serviceName=$(_fetch_service $@)
        if $(hasCmd systemctl); then systemctl stop $serviceName || systemctl disable $serviceName;
        elif $(hasCmd rc-update); then rc-service stop $serviceName || rc-update del $serviceName default; 
        else _ED "SKIP, LIMITED"
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
    local grepInfo=$(parseGet process_data info _);
    local sortCPU=$(parseGet process_data s cpu);
    local sortMEM=$(parseGet process_data S mem);
    local parent=$(parseGet process_data p parent);
    local line=$(parseGet process_data l line);
    local help=$(parseGet process_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t--info,_ \t (string) \t grep process based on info given\n'
    helpmsg+='\t-s,--cpu \t () \t\t sort process by cpu and mem\n'
    helpmsg+='\t-S,--mem \t () \t\t sort process by mem and cpu \n'
    helpmsg+='\t-p,--parent \t (int) \t\t find parent process until reach 1 \n'
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

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$sortCPU"); then sortcpu_process $sortcpu_process;
    elif $(hasValueq "$sortMEM"); then sortmem_process $sortMEM; 
    elif $(hasValueq "$parent"); then parent_process $parent;
    else info_process $grepInfo; 
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
    local exec=$(parseGet dc_data e exec);
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
    helpmsg+='\t-b,--build \t () \t\t build dockerfile \n'
    helpmsg+='\t-B,--rebuild \t () \t\t rebuild dockerfile with no cache \n'
    helpmsg+='\t-e,--exec \t () \t\t exec container with bash or sh \n'
    helpmsg+='\t-E,--execline \t (name,cmd) \t exec cmd on name \n'
    helpmsg+='\t-r,--restart \t () \t\t restart all containers \n'
    helpmsg+='\t-R,--r1,--restart1 \t () \t\t restart 1 container \n'
    helpmsg+='\t-l,--log \t () \t\t log target containers \n'
    helpmsg+='\t-L,--live \t () \t\t live log target containers \n'

    DOCKER=$(which docker);
    
    _find_name() {
        local target="$($DOCKER compose ps -a 2>/dev/null | awk 'NR>1 {print $1}')"
        if ! $(trimArgs "$target" | grep -q " "); then _EC "$target";
        else promptSelect "select target docker compose container:" $target; fi
    }

    up_dc() {
        $DOCKER compose --env-file .env up -d
    }

    down_dc() {
        $DOCKER compose down --remove-orphans
    }

    down1_dc() {
        local name="$(_find_name)"
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
        local name="$(_find_name)"
        $DOCKER compose restart $name
    }

    process_dc() {
        $DOCKER compose ps -a
    }

    build_dc() {
        $DOCKER compose build
    }

    rebuild_dc() {
        $DOCKER compose build --no-cache
    }

    exec_dc() {
        local name="$(_find_name)"
        $DOCKER compose exec --privileged $name /bin/bash||/bin/ash||/bin/sh
    }

    exec_line_dc() {
        local target=$1 cmds="${@:2}"
        $DOCKER compose exec --privileged $target $cmds
    }

    log_dc() {
        local name="$(_find_name)" 
        $DOCKER compose logs ${key} | tail -n 500
    }

    livelog_dc() {
        local name="$(_find_name)"
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
    elif $(hasValueq "$exec"); then exec_dc $exec;
    elif $(hasValueq "$execline"); then exec_line_dc "$execline";
    elif $(hasValueq "$restart"); then restart_dc $restart;
    elif $(hasValueq "$restart1"); then restart1_dc $restart1;
    elif $(hasValueq "$log"); then log_dc $log;
    elif $(hasValueq "$livelog"); then livelog_dc $livelog; 
    fi;
}

# -t,--target,_ (string)
# -d,--dest (string)
tar() { 
    declare -A tar_data; parseArg tar_data $@;
    local target=$(parseGet tar_data t target _);
    local dest=$(parseGet tar_data d dest);
    local help=$(parseGet tar_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-t,--target,_ \t (string) \t target to perform operation\n'
    helpmsg+='\t-d,--dest \t (string) \t when zip, dest loc: default to plaintime.tar; when unzip, dest loc: unzip to target dir \n'

    action_tar() {
        if ! $(hasValueq "$target"); then return $(_ERC "target undefined"); fi;

        TAR=$(which tar);
        FILE=$(which file);
    
        local toZip=false;
        if $(trimArgs "$target" | grep -q " "); then toZip=true; 
        elif ! $($FILE "$target" | grep -q "tar"); then toZip=true; fi;

        if $toZip; then 
            if ! $(hasValueq $dest); then dest="$(dates -p).tar"; fi;
            $TAR -cf $dest $target;
        else 
            if $(hasValueq $dest); then $TAR -xzf $target -C $dest;
            else $TAR -xvf $target; 
            fi; 
        fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    else action_tar; 
    fi;
}

# --large (string, int) large file finder, define [ path, length ]
# --tree,--pstree display pstree
extra() { 
    declare -A extra_data; parseArg extra_data $@;
    local large=$(parseGet extra_data large);
    local tree=$(parseGet extra_data tree pstree);
    local help=$(parseGet extra_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t--large \t\t (string, int) \t large file finder, define [ path=".", length=20 ]\n'
    helpmsg+='\t--tree,--pstree \t () \t\t display pstree\n'
    
    large_extra() {
        local largeDir=$1 largeLength=$2
        if ! $(hasValueq $largeDir); then largeDir="."; fi;
        if ! $(hasValueq $largeLength); then largeLength=20; fi;
        du -ahx $largeDir | sort -rh | head -n $largeLength
    }

    tree_extra() {
        if $(os -c mac); then pstree; 
        else ps auxwwf; fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq "$large"); then large_extra $large;
    elif $(hasValueq "$tree"); then tree_extra $tree; 
    fi;
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
    local path=$(parseGet search_data p path);
    local base=$(parseGet search_data b base);
    local show=$(parseGet search_data s show);
    local ignore=$(parseGet search_data i ignore);
    local depth=$(parseGet search_data D depth);
    local help=$(parseGet search_data help);

    local helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--content,_ \t (string) \t content to search \n'
    helpmsg+='\t-p,--path \t (string) \t search for file or folder name only\n'
    helpmsg+='\t-b,--base \t (string) \t base directory to search in, default "."\n'
    helpmsg+='\t-s,--show \t (int) \t\t show n(*_2) lines of surrounding context\n'
    helpmsg+='\t-i,--ignore \t (string) \t ignore list, use ";" as delimiter \n'
    helpmsg+='\t-D,--depth \t (int) \t\t search depth, default 7\n'

    _load_args() {
        AG_ARGS=""
        # ignore
        local preIgnoreList="$ignore;node_modules;.git;package-lock.json;"
        IFS=';' read -ra elements <<< "$preIgnoreList"
        
        for element in "${elements[@]}"; do
            element="${element#"${element%%[![:space:]]*}"}"
            element="${element%"${element##*[![:space:]]}"}"
            if $(hasValueq $element); then AG_ARGS="$AG_ARGS --ignore $element"; fi;
        done
        # depth
        if ! $(hasValueq $depth); then depth=7; fi;
        AG_ARGS="$AG_ARGS --depth=$depth"
        # show with line
        if ! $(hasValueq "$show"); then AG_ARGS="$AG_ARGS --files-with-matches";
        else AG_ARGS="$AG_ARGS --context $show"; fi;
        # extra
        AG_ARGS="$AG_ARGS --follow --noheading --column"
    }

    content_search() {
        _load_args
        eval $(_EC ag $AG_ARGS "$@" $base)
    }

    path_search() {
        _load_args
        eval $(_EC ag $AG_ARGS -g "$@" $base)
    }

    if $(hasValueq "$help"); then printf "$helpmsg";
    elif $(hasValueq $path); then path_search "$path";
    else content_search "$content";
    fi;
}


# --- EXTRA END ---

# put this at the end of the file
$@;
