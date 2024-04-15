#!/usr/bin/env bash

# Author: Awada.Z

# (): string
version() {
    echo 3.7.1
}

storageDir="$HOME/.application"
storageDirQuick="$storageDir/quick"
storageDirBin="$storageDir/bin"
storageDirBinExtra=$storageDirBin/extra
storageDirTrash="$storageDir/.trash"

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
    profile="$HOME/.bashrc"
    if $(os -c mac); then profile="$HOME/.bash_profile"; fi;
    echo $profile
}

# (number): number
# return callback, set verbose value to enable
_RC() {
    if [ -n "$verbose" ]; then
        echo RC, $1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\) >&2
    fi;
    return $1
}

# (string): number
# error callback, set verbose value to enable
_ERC() {
    if [ -n "$verbose" ]; then
        echo ERC, 1, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), "<x "$1" x>" >&2
    fi;
    return 1
}

# (string): string
# echo callback
_EC() {
    if [ -n "$verbose" ]; then
        echo EC, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \("${@:2:$#}"\), \"\["$1"\]\" >&2
    fi;
    echo "$@"
}

# (string): string
# echo debug
_ED() {
    if [ -n "$verbose" ]; then
        echo ED, 0, $(_UTILDATE), \<${FUNCNAME[ 1 ]}\>, \""$@"\" >&2
    fi;
}

# (declare -A Option, ...data): {key:value, _:"" } 
# example: declare -A data; parseArg data $@; parseGet data _;
parseArg() {
    local -n parse_result=$1;
    _target="_"
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
    path=$(cd "$(dirname "$1")" || exit; pwd)
    file=$(basename "$1")

    if [ "$file" = ".." ]; then
        _EC "$(dirname "$path")"
    else
        _EC  "$path/$file"
    fi
}

# takes in question, and return 1 as yes, 2 as no, default as original response
prompt() {
    read -p "$1" response

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
                echo 0 
            ;;
        esac
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

    value=$(parseGet has_data v value);
    valueQ=$(parseGetQ has_data V Value);
    cmd=$(parseGet has_data c cmd command);
    cmdQ=$(parseGetQ has_data C Cmd Command);
    dir=$(parseGet has_data d dir);
    dirQ=$(parseGetQ has_data D Dir);
    file=$(parseGet has_data f file);
    fileQ=$(parseGetQ has_data F File);
    env=$(parseGet has_data e env);
    envQ=$(parseGetQ has_data E Env);
    help=$(parseGet has_data help);

    helpmsg="${FUNCNAME[0]}:\n"
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


# -c,--check,_ *_default
# -p,--pkgmanager
# -i,--info
os() {
    declare -A os_data; parseArg os_data $@;
    check=$(parseGet os_data c check _);
    pkgmanager=$(parseGet os_data p pkgmanager);
    info=$(parseGet os_data i info);
    help=$(parseGet os_data help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--check,_ \t\t (string) \t check os trait fit current os\n'
    helpmsg+='\t-p,--pkgmanager \t () \t\t get current package manager\n'
    helpmsg+='\t-i,--info \t\t () \t\t get os info\n'

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

    info_os(){
        echo $(pkgManager_os);
        if $(hasCmdq uname); then uname -a; fi;
        if $(hasCmdq sw_vers); then sw_vers; fi;
        if $(hasCmdq lsb_release); then lsb_release -a; fi;
        if $(hasCmdq hostnamectl); then hostnamectl; elif $(hasCmdq hostname); then hostname; fi;
        if [ -f "/etc/os-release" ]; then cat /etc/os-release; fi;
        if $(hasCmdq systeminfo); then systeminfo; fi;
        if $(hasCmdq wmic); then wmic os get Caption, Version, BuildNumber; fi;
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$check"); then check_os $check; 
    elif $(hasValueq "$pkgmanager"); then pkgManager_os;
    elif $(hasValueq "$info"); then info_os;
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
    public=$(parseGet ip_data p public _);
    private=$(parseGet ip_data P private);
    ipv4=$(parseGet ip_data 4 ipv4);
    ipv6=$(parseGet ip_data 6 ipv6);
    help=$(parseGet ip_data h help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--public,_ \t (4/6) \t ipv4 / ipv6, display public ip\n'
    helpmsg+='\t-4,--ipv4 \t () \t use ipv4 to connect to internet\n'
    helpmsg+='\t-6,--ipv6 \t () \t use ipv6 to connect to internet\n'
    helpmsg+='\t-P,--private \t () \t display private ip\n'

    # ():string
    ipLocal() {
        local ethernet wifi

        if $(os -c linux); then
            ips=$(which /sbin/ip || which /usr/sbin/ip);
            ethernet=$($ips addr show eth1 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            wifi=$($ips addr show eth0 2> /dev/null | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
            if $(hasValue $ethernet); then _ED ethernet && _EC $ethernet;
            elif $(hasValue $wifi); then _ED wifi && _EC $wifi; 
            else _ED ip && _EC $($ips route get 1.2.3.4 | awk '{print $7}' | head -1); fi;
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
# -d,--date date only
# -t,--time time only
# -p,--plain plain format as 2000_12_31_23_59_59
# -i,--iso iso8601 format
# -r,--reparse reparse the date format back
# -o,--older current time minus $2 in sec > $1 time
# -s,--second older than seconds, 
dates() {
    declare -A date_data; parseArg date_data $@;
    dateTime=$(parseGet date_data D Datetime _);
    dateOnly=$(parseGet date_data d date);
    timeOnly=$(parseGet date_data t time);
    plain=$(parseGet date_data p plain);
    iso=$(parseGet date_data i iso);
    reparse=$(parseGet date_data r reparse);
    older=$(parseGet date_data o older);
    second=$(parseGet date_data s second);
    help=$(parseGet date_data h help);

    dateFormat='%Y-%m-%d'
    timeFormat='%H:%M:%S'
    dateTimeFormat='%Y-%m-%d %H:%M:%S'
    plainFormat='%Y_%m_%d_%H_%M_%S'
    iso8601="%Y-%m-%dT%H:%M:%S%z"

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-D,--Datetime,_ \t () \t date+time format of date\n'
    helpmsg+='\t-d,--date \t\t () \t date only format of date\n'
    helpmsg+='\t-t,--time \t\t () \t time only format of date\n'
    helpmsg+='\t-p,--plain \t\t () \t plain format of date\n'
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
        additional=$2

        p1="[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+:[0-9]+"
        p2="[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+_[0-9]+"
        p3="[0-9]+-[0-9]+-[0-9]+T"
        p4="[0-9]+-[0-9]+-[0-9]+"
        p5="[0-9]+:[0-9]+:[0-9]+"
        target=""

        if [[ $1 =~ $p1 ]]; then target=$dateTimeFormat; 
        elif [[ $1 =~ $p2 ]]; then target=$plainFormat; 
        elif [[ $1 =~ $p3 ]]; then target=$iso8601; 
        elif [[ $1 =~ $p4 ]]; then target=$dateFormat; 
        elif [[ $1 =~ $p5 ]]; then target=$timeFormat; fi;

        if ! $(hasValueq $target); then return $(_ERC "Error: no pattern found"); 
        else _ED datetime format found, using $target; fi;

        parseDateOS "$1" "$target" $additional
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

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$dateTime"); then toFormat_dates "$dateTimeFormat"; 
    elif $(hasValueq "$dateOnly"); then toFormat_dates "$dateFormat"; 
    elif $(hasValueq "$timeOnly"); then toFormat_dates "$timeFormat"; 
    elif $(hasValueq "$plain"); then toFormat_dates "$plainFormat"; 
    elif $(hasValueq "$iso"); then toFormat_dates "$iso8601"; 
    elif $(hasValueq "$older"); then older_dates $older; 
    elif $(hasValueq "$reparse"); then reparse_dates "$reparse"; 
    else toFormat_dates "$dateTimeFormat"; 
    fi;
}


# -p,--path path to trash, *_default
# -l,--list list trash 
# -r,--restore restore file
# -c,--clean clean trash older than 3 month
# -P,--Purge rm all files from trash dir
trash() {
    declare -A trash_data; parseArg trash_data $@;
    declare -A folder_data;
    path=$(parseGet trash_data p path _);
    list=$(parseGet trash_data l list);
    restore=$(parseGet trash_data r restore);
    clean=$(parseGet trash_data c clean);
    Purge=$(parseGet trash_data P Purge);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-p,--path,_ \t (string) \t move target path to trash path\n'
    helpmsg+='\t-l,--list \t (string) \t list infos on current path, default to list all\n'
    helpmsg+='\t-r,--restore \t (string) \t restore folder depends on current path\n'
    helpmsg+='\t-c,--clean \t (number) \t clean trash older than 3 month, default 7890000 \n'
    helpmsg+='\t-P,--Purge \t () \t remove all trash from trash path\n'

    TP="$storageDirTrash"
    trashInfoName="_u_trash_info"

    put_trash() {
        local input=$1 
        inputPath=$(pathGetFull $input)
        uid="$(uuid)"
        trashDir="$TP/$uid"
        size=$(du -sh $inputPath | awk '{print $1}')
        mkdir -p $trashDir
        mv -fv $inputPath $trashDir
        printf "uuid=$uid \noriginalDir=$inputPath \ndtime=$(date +'%Y-%m-%d %H:%M:%S')\nsize=$size\n" > $trashDir/$trashInfoName
    }

    loadArray() {
        readarray -t folders < <(ls -lt "$TP" | tail -n +2 | awk '{print $9}')
        folder_data[length]=${#folders[@]}
        
        for ((i=0; i<${#folders[@]}; i++)); do
            folder=${folders[i]}
            info_file="$TP/$folder/$trashInfoName"  
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
        indexStr=$1
        evalStr=$2
        
        length=${folder_data[length]}
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
        length=${folder_data[length]}

        for ((i=0; i<$length; i++)); do     
            if $(hasValueq ${folder_data[${i}_uuid]}); then
                index=${folder_data[${i}_index]}
                uuid=${folder_data[${i}_uuid]}
                original_dir=${folder_data[${i}_original_dir]}
                dtime=${folder_data[${i}_dtime]}
                size=${folder_data[${i}_size]}
                printf  "$index\t$original_dir\t\t$dtime\t$size\t$TP/$uuid\n"
            fi;
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

        targetTrashDir=$(echo "$TP/$uuid" | xargs) 
        mv $targetTrashDir/$trashInfoName /tmp
        mv -i $targetTrashDir/* "$(dirname "$original_dir")"
    }

    clean_trash() {
        seconds=7890000
        if (hasValueq $1); then seconds=$1; fi;
        loadArray
        trashFilter "dtime" 'a(){ if $(dates -o $@ -s'" $seconds); then return 0; else return 1; fi; }; a "
        printTrashList 

        if [ ${#folder_data[@]} -lt 2 ]; then
            _ED No available file found
        else
            response=$(prompt "clean these content in $TP ? (no) ")
            if [ $response -eq 1 ]; then
                length=${folder_data[length]}
                for ((i=0; i<$length; i++)); do     
                    if $(hasValueq ${folder_data[${i}_uuid]}); then
                        _ED removing $TP/$uuid
                        rm -rf $TP/$uuid;
                    fi;
                done
                _ED clean complete
            else 
                _ED clean not performed, exit clean
            fi;
        fi;
    }

    purge_trash() {
        response=$(prompt "purge all content in $TP ? (no) ")
        if [ $response -eq 1 ]; then
            rm -rf $TP;
            mkdir -p $TP;
            _ED purge complete
        else 
            _ED purge not performed, exit purge
        fi;
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$path"); then put_trash $path; 
    elif $(hasValueq "$list"); then list_trash $list; 
    elif $(hasValueq "$restore"); then restore_trash $restore; 
    elif $(hasValueq "$clean"); then clean_trash $clean; 
    elif $(hasValueq "$Purge"); then purge_trash $Purge; 
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
string() {
    declare -A string_data; parseArg string_data $@;
    equal=$(parseGet string_data e equal);
    contain=$(parseGet string_data c contain);
    replace=$(parseGet string_data r replace);
    help=$(parseGet string_data help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-e,--equal \t (string,string) \t\t compare two strings\n'
    helpmsg+='\t-c,--contain \t (string,stringOrRegex) \t check if string contains\n'
    helpmsg+='\t-r,--replace \t (string,string,string) \t 1,original string; 2,search string, 3,replacement \n'

    equal_string(){
        if [ "$1" = "$2" ]; then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    contain_string(){
        if $(echo "$1" | grep -q $2); then return $(_RC 0 $@); else return $(_RC 1 $@); fi;
    }

    replace_string(){
        local string=$1 search=$2 replace=$3
        echo "${string//$search/$replace}"
    }

    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$equal"); then equal_string $equal;
    elif $(hasValueq "$contain"); then contain_string $contain;
    elif $(hasValueq "$replace"); then replace_string $replace;
    fi;

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
    json_post(){
        local url=$1 data=$2
        if $(hasCmd wget); then wget -qO- --header "Content-Type: application/json" --post-data "$data" $url;
            elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url";
        fi;
        echo "" 
    }

    # (url, data)
    string_post() {
        local url=$1 data=$2
        if $(hasCmd wget); then wget -qO- --header "Content-Type: text/plain" --post-data "$data" $url;
            elif $(hasCmd curl); then curl -s -X POST -H "Content-Type: text/plain" -d "$data" "$url";
        fi;
        echo ""
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg"; 
    elif $(hasValueq "$string"); then string_post $url $string;
    elif $(hasValueq "$json"); then json_post $url $json; 
    else json_post $url; 
    fi;
}

# -u,--url,_ *_default
# -r,--run
get() {
    declare -A get_data; parseArg get_data $@;
    url=$(parseGet get_data u url _);
    run=$(parseGet get_data r run);
    help=$(parseGet get_data help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-u,--url,_ \t (string) \t url of the target\n'
    helpmsg+='\t-r,--run \t (string) \t run the script from url\n'

    script_get() {
        if $(hasCmd curl); then bash <(curl -s $1); 
        elif $(hasCmd wget); then bash <(wget -O - $1); 
        fi;
    }

    url_get(){
        if $(hasCmd wget); then wget -qO- "$1";
        elif $(hasCmd curl); then curl -s -X GET "$1";
        fi;
        echo ""
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
        if $(hasValue $filename); then wget -O $filename $url; else wget $url; fi;
    elif $(hasCmd curl); then
        if $(hasValue $filename); then curl $url --output $filename; else curl -O $url; fi;
    fi;
}

# -c,--cmd,--command,_ *_default
# -i,--interval
# -r,--retry
retry() {
    declare -A retry_data; parseArg retry_data $@;
    command=$(parseGet retry_data c cmd command _);
    interval=$(parseGet retry_data i interval);
    retry=$(parseGet retry_data r retry)
    help=$(parseGet retry_data h help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-c,--cmd,--command,_ \t (string) \t *_default, command to eval\n'
    helpmsg+='\t-i,interval \t\t (string) \t interval, in seconds, default to 1 sec\n'
    helpmsg+='\t-r,--retry \t\t (string) \t retry, default to 3 times\n'

    if ! $(hasValueq $interval); then interval=1; fi;
    if ! $(hasValueq $retry); then retry=3; fi;

    action_retry(){
        while [[ $retry -ne 0 ]]; do
            _ED retry: $retry, remain
            eval "$command"
            if [[ $? -eq 0 ]]; then
                return $(_RC 0)
            else
                retry=$((retry - 1))
                sleep "$interval"
            fi
        done
        return $(_RC 1)
    }

    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$retry"); then action_retry;
    fi;
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
    name=$(parseGet quick_data n name _ e edit r remove delete c cat display show);
    variable=$(parseGet quick_data v variable);
    add=$(parseGet quick_data a add cmd)
    edit=$(parseGet quick_data e edit);
    display=$(parseGet quick_data c cat display show)
    remove=$(parseGet quick_data r remove delete);
    list=$(parseGet quick_data l list);
    help=$(parseGet quick_data h help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t\t (string) \t *_default, + -e,--edit,-r,--remove,--delete name of the quick data\n'
    helpmsg+='\t-v,--variable \t\t\t (string) \t variable to use\n'
    helpmsg+='\t-a,--add,--cmd \t\t\t () \t\t add command to name\n'
    helpmsg+='\t-e,--edit \t\t\t () \t\t edit the target file\n'
    helpmsg+='\t-c,--cat,--display,--show \t () \t\t display the content of file\n'
    helpmsg+='\t-r,--remove,--delete \t\t () \t\t remove the target file\n'
    helpmsg+='\t-l,--list \t\t\t () \t\t list total quick command\n'

    name=$(echo $name | sed 's/ *//')
    targetFile="$storageDirQuick/$name"

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
        if $(hasFile $targetFile); then if $(hasCmd trash); then trash $targetFile; else rm -r $targetFile; fi; fi;
    }
    
    if $(hasValueq "$help"); then printf "$helpmsg";  
    elif $(hasValueq "$list"); then ls -a $storageDirQuick;
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
    profile="$(_PROFILE)"
    mkdir -p $storageDirBin && mkdir -p $storageDirBinExtra && mkdir -p $storageDirQuick && mkdir -p $storageDirTrash

    if ! $(hasFile "$HOME/.bash_mine"); then
        touch $HOME/.bash_mine && touch $HOME/.bash_env
        echo 'source $HOME/.bash_mine' >> $profile
        echo 'source $HOME/.bash_env' >> $HOME/.bash_mine
        
        echo 'if [ "$PWD" = "$HOME" ]; then cd Documents; fi;' >> $HOME/.bash_mine
        echo 'PATH=$HOME/.npm_global/bin:'$storageDirBin':$PATH' >> $HOME/.bash_mine
        echo 'function cdd { _back=$(pwd) && cd $@ && ls -a; }' >> $HOME/.bash_mine
        echo 'function cdb { _oldback=$_back && _back=$(pwd) && cd $_oldback && ls -a; }' >> $HOME/.bash_mine

        printf 'export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\nexport NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16\n\n' >> $HOME/.bash_mine 
        printf 'if [[ ! -z "$u_proxy" ]] && curl --output /dev/null --silent --head "$u_proxy"; then\n export https_proxy=$u_proxy\n export http_proxy=$u_proxy\n export HTTPS_PROXY=$u_proxy\n export HTTP_PROXY=$u_proxy\nfi;\n'  >> $HOME/.bash_mine

        if $(os -c mac); then printf 'export BASH_SILENCE_DEPRECATION_WARNING=1\n' >> $HOME/.bash_mine; fi;
    fi;

    mv $(_SCRIPTPATHFULL) $storageDirBin/u2
    . $storageDirBin/u2 _ED Current Version: $(version)
}

edit(){
    if $(hasCmd nano); then nano $(_SCRIPTPATHFULL);
    elif $(hasCmd vi); then vi $(_SCRIPTPATHFULL); fi;
}

# -n,--name,_ *_default
# -u,--update,--upgrade
# -v,--version
# -h,--help
help(){    
    declare -A help_data; parseArg help_data $@;
    name=$(parseGet help_data n name _);
    update=$(parseGet help_data u update upgrade);
    version=$(parseGet help_data v version);
    help=$(parseGet help_data h help);

    helpmsg="${FUNCNAME[0]}:\n"
    helpmsg+='\t-n,--name,_ \t\t (string) \t grep functions with name\n'
    helpmsg+='\t-u,--update,--upgrade \t () \t\t upgrade current script\n'
    helpmsg+='\t-v,--version \t\t (string) \t display current version\n'
    helpmsg+='\t-h,--help \t\t (string) \t display help message\n'

    update_help() {
        _ED Current Version: $(version)
        local scriptLoc="$storageDirBin/u2"
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

if [ -d $storageDirBinExtra ]; then for i in $(ls $storageDirBinExtra); do source $storageDirBinExtra/$i; done; fi;

# put this at the end of the file
$@;
